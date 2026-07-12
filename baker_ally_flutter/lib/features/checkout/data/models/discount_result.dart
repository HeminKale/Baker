/// Server-validated discount (05_cart_and_checkout.md §9). `discountValue` is
/// paise taken off the subtotal; `freeShipping` waives the delivery line.
class DiscountResult {
  const DiscountResult({
    required this.code,
    required this.type,
    required this.value,
    required this.discountValue,
    required this.freeShipping,
  });

  final String code;
  final String type; // 'percent' | 'flat' | 'free_shipping'
  final int value;
  final int discountValue;
  final bool freeShipping;

  factory DiscountResult.fromJson(Map<String, dynamic> json) {
    return DiscountResult(
      code: json['code'] as String,
      type: json['type'] as String,
      value: json['value'] as int? ?? 0,
      discountValue: json['discountValue'] as int? ?? 0,
      freeShipping: json['freeShipping'] as bool? ?? false,
    );
  }
}
