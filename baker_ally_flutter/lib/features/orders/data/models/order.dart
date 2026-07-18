/// A row from `GET /orders` (06_profile_and_account.md Your Orders).
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.discountValue,
    required this.shippingCost,
    required this.total,
    required this.createdAt,
    required this.itemCount,
    this.thumbnailUrl,
  });

  final String id;
  final String status;
  final int subtotal;
  final int discountValue;
  final int shippingCost;
  final int total;
  final DateTime createdAt;
  final int itemCount;
  final String? thumbnailUrl;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      status: json['status'] as String,
      subtotal: json['subtotal'] as int,
      discountValue: json['discountValue'] as int? ?? 0,
      shippingCost: json['shippingCost'] as int? ?? 0,
      total: json['total'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      itemCount: json['itemCount'] as int? ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}
