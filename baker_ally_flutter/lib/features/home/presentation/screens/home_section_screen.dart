import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/data/models/product.dart';
import '../../../catalog/presentation/widgets/product_tile.dart';
import '../../data/models/home_sections.dart';
import '../providers/home_providers.dart';

/// "See all" destination for one Home section -- 01_home_tab.md §8. Generic,
/// parameterized by section, so there's one screen instead of three
/// near-identical ones.
class HomeSectionScreen extends ConsumerWidget {
  const HomeSectionScreen({super.key, required this.section});

  final HomeSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstPageAsync = ref.watch(homeSectionPageProvider((section: section, page: 1)));

    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: firstPageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (firstPage) => firstPage.isEmpty
            ? const Center(child: Text('Nothing here yet'))
            : _SectionGrid(section: section, firstPage: firstPage),
      ),
    );
  }
}

/// Accumulates pages locally on "Load More" -- same pattern as Order Again's
/// Previously Bought pagination in Milestone 5.
class _SectionGrid extends ConsumerStatefulWidget {
  const _SectionGrid({required this.section, required this.firstPage});

  final HomeSection section;
  final List<Product> firstPage;

  @override
  ConsumerState<_SectionGrid> createState() => _SectionGridState();
}

class _SectionGridState extends ConsumerState<_SectionGrid> {
  static const _limit = 20;
  final List<Product> _extraPages = [];
  int _nextPage = 2;
  bool _hasMore = true;
  bool _loadingMore = false;

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final items = await ref
          .read(homeRepositoryProvider)
          .getSection(widget.section, page: _nextPage, limit: _limit);
      setState(() {
        _extraPages.addAll(items);
        _nextPage++;
        _hasMore = items.length == _limit;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load more: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.firstPage, ..._extraPages];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.45,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => ProductTile(product: items[index]),
        ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(onPressed: _loadMore, child: const Text('Load More')),
            ),
          ),
      ],
    );
  }
}
