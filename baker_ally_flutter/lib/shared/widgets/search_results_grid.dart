import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/presentation/providers/catalog_providers.dart';
import '../../features/catalog/presentation/widgets/product_tile.dart';

/// Renders `searchProvider`'s live results as a 2-column grid -- used by both
/// Catalog's search (icon-toggled) and Home's search (always-visible bar),
/// per 00_common_architecture.md §2's "same results, different display"
/// search behaviour.
class SearchResultsGrid extends ConsumerWidget {
  const SearchResultsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchProvider);

    if (search.query.trim().isEmpty) {
      return const Center(child: Text('Type to search products'));
    }
    if (search.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (search.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No results for "${search.query}"\nTry a different spelling or browse categories',
              textAlign: TextAlign.center),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.45,
      ),
      itemCount: search.results.length,
      itemBuilder: (context, index) => ProductTile(product: search.results[index]),
    );
  }
}
