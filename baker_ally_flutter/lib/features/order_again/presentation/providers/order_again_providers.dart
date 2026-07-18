import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/models/order_again_variant.dart';
import '../../data/order_again_repository.dart';

final orderAgainRepositoryProvider = Provider<OrderAgainRepository>((ref) {
  return OrderAgainRepository(dio: ref.watch(dioProvider));
});

final frequentlyBoughtProvider = FutureProvider.autoDispose<List<FrequentlyBoughtGroup>>((ref) async {
  return ref.watch(orderAgainRepositoryProvider).getFrequentlyBought();
});

/// Search text + selected month for the "Previously Bought" grid only --
/// Frequently Bought Together isn't tied to a single month, so it doesn't
/// watch this.
class OrderAgainFilter {
  const OrderAgainFilter({this.search = '', this.month});

  final String search;
  final String? month; // "YYYY-MM", null = all time

  OrderAgainFilter copyWith({String? search, String? month, bool clearMonth = false}) {
    return OrderAgainFilter(
      search: search ?? this.search,
      month: clearMonth ? null : (month ?? this.month),
    );
  }
}

final orderAgainFilterProvider = StateProvider.autoDispose<OrderAgainFilter>((ref) => const OrderAgainFilter());

final previouslyBoughtProvider = FutureProvider.autoDispose<List<PreviouslyBoughtItem>>((ref) async {
  final filter = ref.watch(orderAgainFilterProvider);
  final search = filter.search.trim();
  return ref.watch(orderAgainRepositoryProvider).getPreviouslyBought(
        search: search.isEmpty ? null : search,
        month: filter.month,
      );
});
