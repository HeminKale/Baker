import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../catalog/data/models/product.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/address_repository.dart';
import '../../data/checkout_repository.dart';
import '../../data/models/address.dart';
import '../../data/models/discount_result.dart';

/// Flat delivery fee -- PLACEHOLDER pending the Porter / free-shipping decision
/// (00_common_architecture.md §17). MUST match the backend's FLAT_SHIPPING_PAISE
/// in routes/checkout.ts, else POST /cart/checkout returns PRICE_CHANGED.
const int kFlatShippingPaise = 4900;

enum PaymentMethod { upi, card, netbanking }

enum CheckoutStatus { idle, validatingPrices, openingRazorpay, confirming, success, failed }

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(dio: ref.watch(dioProvider), db: ref.watch(appDatabaseProvider));
});

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(dio: ref.watch(dioProvider));
});

final addressesProvider = FutureProvider<List<Address>>((ref) async {
  return ref.watch(addressRepositoryProvider).getAddresses();
});

/// Selected delivery address for checkout (05_cart_and_checkout.md §12).
final selectedAddressProvider = StateProvider<Address?>((ref) => null);

final selectedPaymentMethodProvider = StateProvider<PaymentMethod>((ref) => PaymentMethod.upi);

final checkoutStatusProvider = StateProvider<CheckoutStatus>((ref) => CheckoutStatus.idle);

/// The discount currently applied to the bill (null = none). Set by the
/// checkout screen after POST /v1/discounts/validate succeeds.
final appliedDiscountProvider = StateProvider<DiscountResult?>((ref) => null);

/// "You Might Also Like" -- other products from the cart's subcategories.
final checkoutRecommendationsProvider = FutureProvider<List<Product>>((ref) async {
  final cart = ref.watch(cartProvider);
  final ids = cart.items.map((i) => i.variantId).toList();
  if (ids.isEmpty) return const [];
  return ref.watch(checkoutRepositoryProvider).getRecommendations(ids);
});

/// Live bill breakdown -- recomputed whenever the cart or applied discount
/// changes. Mirrors the server's arithmetic so `expectedTotal` matches.
class BillSummary {
  const BillSummary({
    required this.subtotal,
    required this.discountValue,
    required this.shippingCost,
    required this.total,
  });

  final int subtotal;
  final int discountValue;
  final int shippingCost;
  final int total;
}

final billSummaryProvider = Provider<BillSummary>((ref) {
  final subtotal = ref.watch(cartProvider.select((s) => s.subtotal));
  final discount = ref.watch(appliedDiscountProvider);

  // Recompute the discount against the LIVE subtotal, mirroring the server's
  // discountEngine.ts arithmetic exactly. Using the value frozen at validate
  // time would go stale the moment the cart changes and make POST /cart/checkout
  // keep returning PRICE_CHANGED (the client's total never catching up).
  var discountValue = 0;
  var freeShipping = false;
  if (discount != null) {
    switch (discount.type) {
      case 'percent':
        discountValue = (subtotal * discount.value / 100).round();
      case 'flat':
        discountValue = discount.value < subtotal ? discount.value : subtotal;
      case 'free_shipping':
        freeShipping = true;
    }
  }

  // No shipping charged on an empty cart.
  final shippingCost = subtotal == 0 ? 0 : (freeShipping ? 0 : kFlatShippingPaise);
  final total = subtotal - discountValue + shippingCost;
  return BillSummary(
    subtotal: subtotal,
    discountValue: discountValue,
    shippingCost: shippingCost,
    total: total < 0 ? 0 : total,
  );
});
