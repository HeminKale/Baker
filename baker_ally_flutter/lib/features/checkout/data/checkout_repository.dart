import 'package:dio/dio.dart';

import '../../catalog/data/models/product.dart';
import 'models/discount_result.dart';

/// Returned by POST /v1/cart/checkout -- everything Flutter needs to open the
/// Razorpay sheet.
class CheckoutSession {
  const CheckoutSession({
    required this.orderId,
    required this.razorpayOrderId,
    required this.amount,
    required this.keyId,
  });

  final String orderId;
  final String razorpayOrderId;
  final int amount; // paise
  final String keyId;
}

/// Server recomputed a different total than the client displayed -- carries the
/// corrected breakdown so the bill can be updated before retry.
class PriceChangedException implements Exception {
  const PriceChangedException({
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

/// An item went out of stock between add and checkout.
class OutOfStockException implements Exception {
  const OutOfStockException(this.message);
  final String message;
}

/// Discount code rejected at validate or checkout time.
class DiscountInvalidException implements Exception {
  const DiscountInvalidException(this.message);
  final String message;
}

class CheckoutRepository {
  CheckoutRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Product>> getRecommendations(List<String> variantIds) async {
    if (variantIds.isEmpty) return [];
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/checkout/recommendations',
      queryParameters: {'variantIds': variantIds.join(',')},
    );
    return (response.data!['data'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DiscountResult> validateDiscount(String code, int cartTotal) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/discounts/validate',
        data: {'code': code, 'cartTotal': cartTotal},
      );
      return DiscountResult.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DiscountInvalidException(_errorMessage(e) ?? 'Invalid or expired code');
    }
  }

  Future<CheckoutSession> createCheckout({
    required String addressId,
    String? discountCode,
    required int expectedTotal,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/cart/checkout',
        data: {
          'addressId': addressId,
          if (discountCode != null && discountCode.isNotEmpty) 'discountCode': discountCode,
          'expectedTotal': expectedTotal,
        },
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return CheckoutSession(
        orderId: data['orderId'] as String,
        razorpayOrderId: data['razorpayOrderId'] as String,
        amount: data['amount'] as int,
        keyId: data['keyId'] as String,
      );
    } on DioException catch (e) {
      final error = e.response?.data is Map ? (e.response!.data['error'] as Map?) : null;
      final code = error?['code'] as String?;
      if (code == 'PRICE_CHANGED') {
        final b = error!['breakdown'] as Map<String, dynamic>;
        throw PriceChangedException(
          subtotal: b['subtotal'] as int,
          discountValue: b['discountValue'] as int,
          shippingCost: b['shippingCost'] as int,
          total: b['total'] as int,
        );
      }
      if (code == 'OUT_OF_STOCK') {
        throw OutOfStockException((error!['message'] as String?) ?? 'Some items are no longer available');
      }
      if (code != null && code.startsWith('DISCOUNT')) {
        throw DiscountInvalidException((error!['message'] as String?) ?? 'Discount no longer valid');
      }
      rethrow;
    }
  }

  Future<void> confirmOrder({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/v1/orders/$orderId/confirm',
      data: {'razorpayPaymentId': razorpayPaymentId, 'razorpaySignature': razorpaySignature},
    );
  }

  String? _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      return data['error']['message'] as String?;
    }
    return null;
  }
}
