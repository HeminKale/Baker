import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category.dart';
import '../providers/catalog_providers.dart';
import '../widgets/product_tile.dart';
import '../widgets/subcategory_tile.dart';

/// Level 1 -- single vertical scroll, bold non-tappable category headings,
/// horizontal subcategory tile rows underneath each.
/// Planning docs/Architecture/02_catalog_tab.md §2.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  bool _searchExpanded = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchExpanded = !_searchExpanded);
    if (!_searchExpanded) {
      _searchController.clear();
      ref.read(searchProvider.notifier).onQueryChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchExpanded
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search ingredients, packaging...',
                  border: InputBorder.none,
                ),
                onChanged: (q) => ref.read(searchProvider.notifier).onQueryChanged(q),
              )
            : const Text('Catalog'),
        actions: [
          IconButton(icon: Icon(_searchExpanded ? Icons.close : Icons.search), onPressed: _toggleSearch),
        ],
      ),
      // Search results replace the screen content while active, per
      // 00_common_architecture.md §2 "Search behaviour".
      body: _searchExpanded ? const _CatalogSearchResults() : const _CatalogBody(),
    );
  }
}

class _CatalogBody extends ConsumerWidget {
  const _CatalogBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final lastSynced = ref.watch(catalogLastSyncedProvider).valueOrNull;
    final isStale = lastSynced != null && DateTime.now().difference(lastSynced).inHours >= 24;

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Failed to load catalog: $error')),
      data: (categories) {
        return ListView(
          children: [
            if (isStale)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Last updated ${DateTime.now().difference(lastSynced).inHours} hours ago'),
              ),
            for (final category in categories) _CategorySection(category: category),
          ],
        );
      },
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subCategoriesAsync = ref.watch(subCategoriesProvider(category.id));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: subCategoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Failed to load: $error')),
              data: (subCategories) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: subCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SubcategoryTile(
                  categoryId: category.id,
                  subCategory: subCategories[index],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogSearchResults extends ConsumerWidget {
  const _CatalogSearchResults();

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
