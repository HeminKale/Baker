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

final previouslyBoughtProvider = FutureProvider.autoDispose<List<PreviouslyBoughtItem>>((ref) async {
  return ref.watch(orderAgainRepositoryProvider).getPreviouslyBought();
});
