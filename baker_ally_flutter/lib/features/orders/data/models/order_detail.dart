import '../../../checkout/data/models/address.dart';
import 'order.dart';

/// A row from `GET /order_items` embedded in `GET /orders/:id`.
class OrderItem {
  const OrderItem({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String variantId;
  final String productName;
  final String variantName;
  final int quantity;
  final int unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      variantId: json['variantId'] as String,
      productName: json['productName'] as String,
      variantName: json['variantName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: json['unitPrice'] as int,
    );
  }
}

/// `GET /orders/:id` -- the list `Order` plus its line items and delivery
/// address. Not cached in Drift (product-detail-style precedent).
class OrderDetail {
  const OrderDetail({required this.order, required this.items, required this.address});

  final Order order;
  final List<OrderItem> items;
  final Address? address;

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      order: Order.fromJson(json),
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      address: json['address'] != null ? Address.fromJson(json['address'] as Map<String, dynamic>) : null,
    );
  }
}
