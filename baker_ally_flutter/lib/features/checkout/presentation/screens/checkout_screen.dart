import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../shared/widgets/login_required_sheet.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../catalog/presentation/widgets/product_tile.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/checkout_repository.dart';
import '../providers/checkout_providers.dart';
import '../widgets/address_selector_sheet.dart';
import '../widgets/cart_item_row.dart';
import '../widgets/payment_mode_sheet.dart';

String _paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.upi:
      return 'UPI';
    case PaymentMethod.card:
      return 'Card';
    case PaymentMethod.netbanking:
      return 'Netbanking';
  }
}

/// The Cart tab IS the checkout page (05_cart_and_checkout.md §3 -- no separate
/// cart-review screen). Single scrollable page + fixed bottom CTA. Owns the
/// Razorpay instance for the whole checkout lifecycle.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final Razorpay _razorpay;
  final _discountController = TextEditingController();

  String? _pendingOrderId;
  int _pendingTotal = 0;
  bool _applyingDiscount = false;
  String? _discountError;
  String? _banner;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _discountController.dispose();
    super.dispose();
  }

  void _setStatus(CheckoutStatus status) {
    ref.read(checkoutStatusProvider.notifier).state = status;
  }

  Future<void> _applyDiscount() async {
    final code = _discountController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _applyingDiscount = true;
      _discountError = null;
    });
    final subtotal = ref.read(cartProvider).subtotal;
    try {
      final result = await ref.read(checkoutRepositoryProvider).validateDiscount(code, subtotal);
      ref.read(appliedDiscountProvider.notifier).state = result;
    } on DiscountInvalidException catch (e) {
      setState(() => _discountError = e.message);
    } catch (_) {
      setState(() => _discountError = 'Could not validate code');
    } finally {
      if (mounted) setState(() => _applyingDiscount = false);
    }
  }

  void _removeDiscount() {
    ref.read(appliedDiscountProvider.notifier).state = null;
    _discountController.clear();
    setState(() => _discountError = null);
  }

  Future<void> _placeOrder() async {
    if (!ref.read(authProvider).isLoggedIn) {
      showLoginRequiredSheet(context);
      return;
    }
    final address = ref.read(selectedAddressProvider);
    if (address == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please add a delivery address')));
      AddressSelectorSheet.show(context);
      return;
    }
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;

    final bill = ref.read(billSummaryProvider);
    final applied = ref.read(appliedDiscountProvider);
    setState(() => _banner = null);
    _setStatus(CheckoutStatus.validatingPrices);

    try {
      final session = await ref.read(checkoutRepositoryProvider).createCheckout(
            addressId: address.id,
            discountCode: applied?.code,
            expectedTotal: bill.total,
          );
      _pendingOrderId = session.orderId;
      _pendingTotal = session.amount;
      _setStatus(CheckoutStatus.openingRazorpay);
      _razorpay.open({
        'key': session.keyId,
        'order_id': session.razorpayOrderId,
        'amount': session.amount,
        'currency': 'INR',
        'name': 'Baker Ally',
        'description': 'Order payment',
      });
    } on PriceChangedException {
      await ref.read(cartProvider.notifier).refresh();
      _setStatus(CheckoutStatus.idle);
      setState(() => _banner = 'Prices changed since your cart was built. Please review the updated total.');
    } on OutOfStockException catch (e) {
      await ref.read(cartProvider.notifier).refresh();
      _setStatus(CheckoutStatus.idle);
      setState(() => _banner = e.message);
    } on DiscountInvalidException catch (e) {
      _removeDiscount();
      _setStatus(CheckoutStatus.idle);
      setState(() => _banner = e.message);
    } catch (e) {
      _setStatus(CheckoutStatus.failed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
      }
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    _setStatus(CheckoutStatus.confirming);
    try {
      await ref.read(checkoutRepositoryProvider).confirmOrder(
            orderId: _pendingOrderId!,
            razorpayPaymentId: response.paymentId!,
            razorpaySignature: response.signature!,
          );
      await ref.read(cartProvider.notifier).clearAfterOrder();
      ref.read(appliedDiscountProvider.notifier).state = null;
      _setStatus(CheckoutStatus.success);
      if (mounted) {
        context.go('/checkout/confirmation', extra: {
          'orderId': _pendingOrderId,
          'total': _pendingTotal,
          'paymentMethod': _paymentMethodLabel(ref.read(selectedPaymentMethodProvider)),
        });
      }
    } catch (e) {
      _setStatus(CheckoutStatus.failed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment received but confirmation failed. Contact support. ($e)')),
        );
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _setStatus(CheckoutStatus.failed);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response.message ?? 'cancelled'}')),
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // No-op: external wallet selection is confirmed via the standard success flow.
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final status = ref.watch(checkoutStatusProvider);

    // Preselect the default address once addresses load and nothing is chosen.
    ref.listen(addressesProvider, (prev, next) {
      next.whenData((addresses) {
        if (ref.read(selectedAddressProvider) == null && addresses.isNotEmpty) {
          final def = addresses.where((a) => a.isDefault);
          ref.read(selectedAddressProvider.notifier).state = def.isNotEmpty ? def.first : addresses.first;
        }
      });
    });

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Cart')),
        body: _EmptyCart(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Your Order · ${cart.totalItems} items')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        children: [
          if (_banner != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_banner!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
            ),
          const _SectionHeader('ITEMS IN YOUR CART'),
          for (final item in cart.items) CartItemRow(item: item),
          const SizedBox(height: 16),
          const _SectionHeader('YOU MIGHT ALSO LIKE'),
          const _Recommendations(),
          const SizedBox(height: 16),
          const _SectionHeader('BILL DETAILS'),
          _BillDetails(
            discountController: _discountController,
            applying: _applyingDiscount,
            discountError: _discountError,
            onApply: _applyDiscount,
            onRemove: _removeDiscount,
          ),
          const SizedBox(height: 16),
          const _CancellationPolicy(),
        ],
      ),
      bottomSheet: _CtaBar(
        status: status,
        onProceed: _placeOrder,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Add items from the catalog to begin'),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => context.go('/catalog'), child: const Text('Browse Catalog')),
        ],
      ),
    );
  }
}

class _Recommendations extends ConsumerWidget {
  const _Recommendations();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(checkoutRecommendationsProvider);
    return recsAsync.when(
      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SizedBox.shrink(),
      data: (recs) {
        if (recs.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => SizedBox(width: 160, child: ProductTile(product: recs[i])),
          ),
        );
      },
    );
  }
}

class _BillDetails extends ConsumerWidget {
  const _BillDetails({
    required this.discountController,
    required this.applying,
    required this.discountError,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController discountController;
  final bool applying;
  final String? discountError;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = ref.watch(billSummaryProvider);
    final applied = ref.watch(appliedDiscountProvider);

    Widget line(String label, String value, {bool discount = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: TextStyle(color: discount ? Colors.green : null)),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line('Item total', _rupees(bill.subtotal)),
            if (bill.discountValue > 0)
              line('Discount${applied != null ? ' (${applied.code})' : ''}', '− ${_rupees(bill.discountValue)}',
                  discount: true),
            line('Delivery charges', bill.shippingCost == 0 ? 'FREE' : _rupees(bill.shippingCost)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('To pay', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_rupees(bill.total), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (applied != null)
              Row(
                children: [
                  Expanded(
                    child: Text('✅ ${applied.code} applied — ${_rupees(bill.discountValue)} saved',
                        style: const TextStyle(color: Colors.green)),
                  ),
                  TextButton(onPressed: onRemove, child: const Text('Remove')),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: discountController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter discount code',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        errorText: discountError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: applying ? null : onApply,
                    child: applying
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Apply'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CancellationPolicy extends StatelessWidget {
  const _CancellationPolicy();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CANCELLATION POLICY',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Orders can be cancelled within 2 hours of placement. Once dispatched, cancellations '
                'are not accepted. For returns, contact us within 24 hours of delivery.'),
          ],
        ),
      ),
    );
  }
}

class _CtaBar extends ConsumerWidget {
  const _CtaBar({required this.status, required this.onProceed});

  final CheckoutStatus status;
  final VoidCallback onProceed;

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(selectedAddressProvider);
    final payment = ref.watch(selectedPaymentMethodProvider);
    final bill = ref.watch(billSummaryProvider);
    final busy = status == CheckoutStatus.validatingPrices ||
        status == CheckoutStatus.openingRazorpay ||
        status == CheckoutStatus.confirming;

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(
                address == null ? 'Add delivery address' : '${address.label ?? 'Address'}, ${address.shortLine}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: address == null ? Colors.red : null),
              ),
              trailing: TextButton(
                onPressed: () => AddressSelectorSheet.show(context),
                child: Text(address == null ? 'Add' : 'Change'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => PaymentModeSheet.show(context),
                    child: Row(
                      children: [
                        const Icon(Icons.payment, size: 18),
                        const SizedBox(width: 4),
                        Text(_paymentMethodLabel(payment)),
                        const Icon(Icons.keyboard_arrow_up, size: 18),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(_rupees(bill.total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 12),
                  FilledButton(
                    // Enabled even with no address selected: a guest taps this
                    // to get the login sheet, a logged-in user to get the
                    // address sheet -- _placeOrder gates login -> address ->
                    // pay in order (05_cart_and_checkout.md §2/§3/§5).
                    onPressed: busy ? null : onProceed,
                    child: busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Proceed →'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
