import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/search_results_grid.dart';
import '../../../../shared/widgets/voice_search_button.dart';
import '../../../catalog/data/models/product.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../catalog/presentation/widgets/product_tile.dart';
import '../../data/models/home_sections.dart';
import '../providers/home_providers.dart';

/// First tab -- 01_home_tab.md. Search bar is always visible here (not an
/// icon toggle like every other screen, per 00_common_architecture.md §2's
/// search-display table), so search results simply replace the three
/// sections below it while a query is active -- no separate search screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
            Expanded(child: query.trim().isEmpty ? const _HomeSections() : const SearchResultsGrid()),
          ],
        ),
      ),
    );
  }
}

class _HomeSections extends ConsumerWidget {
  const _HomeSections();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(homeSectionsProvider);

    return sectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load: $error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(homeSectionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (sections) {
        // A section with zero qualifying products is hidden entirely, not
        // shown empty -- 01_home_tab.md §14.
        final visible = [
          if (sections.newlyLaunched.isNotEmpty) (HomeSection.newlyLaunched, sections.newlyLaunched),
          if (sections.newOffers.isNotEmpty) (HomeSection.newOffers, sections.newOffers),
          if (sections.trending.isNotEmpty) (HomeSection.trending, sections.trending),
        ];

        if (visible.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nothing to show here yet.', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push('/catalog'),
                    child: const Text('Browse the catalog'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [for (final (section, products) in visible) _SectionRow(section: section, products: products)],
        );
      },
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.section, required this.products});

  final HomeSection section;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(section.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.push('/home/section/${section.apiSlug}'),
                  child: const Text('See all →'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 316,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => SizedBox(width: 160, child: ProductTile(product: products[i])),
            ),
          ),
        ],
      ),
    );
  }
}
