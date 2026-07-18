import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../catalog/data/models/product.dart';
import '../../data/home_repository.dart';
import '../../data/models/home_sections.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(dio: ref.watch(dioProvider), db: ref.watch(appDatabaseProvider));
});

final homeSectionsProvider = FutureProvider.autoDispose<HomeSections>((ref) async {
  return ref.watch(homeRepositoryProvider).getHomeSections();
});

/// "See all" pagination -- one page per call, the screen accumulates pages
/// itself (same local-page-state pattern as Order Again's Previously Bought
/// "Load More", not a new provider-layer pagination primitive).
final homeSectionPageProvider =
    FutureProvider.autoDispose.family<List<Product>, ({HomeSection section, int page})>((ref, args) async {
  return ref.watch(homeRepositoryProvider).getSection(args.section, page: args.page);
});
