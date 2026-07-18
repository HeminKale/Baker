import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/search_results_grid.dart';
import '../../../../shared/widgets/voice_search_button.dart';
import '../../data/models/category.dart';
import '../providers/catalog_providers.dart';
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
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onVoiceResult(String words) {
    _searchController.text = words;
    ref.read(searchProvider.notifier).onQueryChanged(words);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchProvider.select((s) => s.query));

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search ingredients, packaging...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: VoiceSearchButton(onResult: _onVoiceResult),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                  isDense: true,
                ),
                onChanged: (q) => ref.read(searchProvider.notifier).onQueryChanged(q),
              ),
            ),
            // Search results replace the screen content while active, per
            // 00_common_architecture.md §2 "Search behaviour".
            Expanded(child: query.trim().isEmpty ? const _CatalogBody() : const SearchResultsGrid()),
          ],
        ),
      ),
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
