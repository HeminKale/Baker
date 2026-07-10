import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/models/sub_category.dart';
import '../providers/catalog_providers.dart';
import '../widgets/product_tile.dart';

/// Level 2 -- left subcategory strip (~5% width, independently scrollable)
/// + right product grid grouped by subcategory, scroll-spy synced in both
/// directions. Planning docs/Architecture/02_catalog_tab.md §3.
class SubcategoryProductsScreen extends ConsumerStatefulWidget {
  const SubcategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.initialSubCategoryId,
  });

  final String categoryId;
  final String initialSubCategoryId;

  @override
  ConsumerState<SubcategoryProductsScreen> createState() => _SubcategoryProductsScreenState();
}

class _SubcategoryProductsScreenState extends ConsumerState<SubcategoryProductsScreen> {
  final ScrollController _gridController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _stripKeys = {};
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _gridController.addListener(_onGridScroll);
  }

  @override
  void dispose() {
    _gridController.removeListener(_onGridScroll);
    _gridController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(Map<String, GlobalKey> map, String id) => map.putIfAbsent(id, GlobalKey.new);

  void _onGridScroll() {
    final viewportBox = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.attached) return;

    String? activeId;
    double bestTop = double.negativeInfinity;
    const threshold = 80.0; // small allowance so a header just below the top still counts as active
    for (final entry in _sectionKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero, ancestor: viewportBox).dy;
      if (top <= threshold && top > bestTop) {
        bestTop = top;
        activeId = entry.key;
      }
    }
    if (activeId != null && activeId != ref.read(activeSubcategoryProvider(widget.categoryId))) {
      ref.read(activeSubcategoryProvider(widget.categoryId).notifier).state = activeId;
      final stripKey = _stripKeys[activeId];
      final stripContext = stripKey?.currentContext;
      if (stripContext != null) {
        Scrollable.ensureVisible(stripContext, duration: const Duration(milliseconds: 200));
      }
    }
  }

  void _scrollToSection(String subCategoryId) {
    ref.read(activeSubcategoryProvider(widget.categoryId).notifier).state = subCategoryId;
    final sectionContext = _sectionKeys[subCategoryId]?.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(sectionContext, alignment: 0, duration: const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    final subCategoriesAsync = ref.watch(subCategoriesProvider(widget.categoryId));
    final productsAsync = ref.watch(categoryProductsProvider(widget.categoryId));
    final activeSubCategoryId = ref.watch(activeSubcategoryProvider(widget.categoryId));

    return Scaffold(
      appBar: AppBar(
        title: subCategoriesAsync.maybeWhen(
          data: (subs) {
            final name = subs.isEmpty ? '' : subs.first.name;
            return Text(name);
          },
          orElse: () => const Text(''),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: () => _showFilterSheet(context)),
        ],
      ),
      body: subCategoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (subCategories) {
          if (!_didInitialScroll) {
            _didInitialScroll = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection(widget.initialSubCategoryId));
          }
          final products = productsAsync.valueOrNull ?? const <Product>[];
          final filter = ref.watch(catalogFilterProvider(widget.categoryId));

          return Row(
            children: [
              SizedBox(
                width: 44,
                child: ListView.builder(
                  itemCount: subCategories.length,
                  itemBuilder: (context, index) {
                    final sub = subCategories[index];
                    final isActive = sub.id == activeSubCategoryId;
                    return InkWell(
                      key: _keyFor(_stripKeys, sub.id),
                      onTap: () => _scrollToSection(sub.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            sub.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Container(
                  key: _viewportKey,
                  child: productsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Failed to load: $e')),
                    data: (_) => ListView.builder(
                      controller: _gridController,
                      itemCount: subCategories.length,
                      itemBuilder: (context, index) {
                        final sub = subCategories[index];
                        final sectionProducts = _applyFilter(
                          products.where((p) => p.subCategoryId == sub.id).toList(),
                          filter,
                        );
                        return _SubCategorySection(
                          key: _keyFor(_sectionKeys, sub.id),
                          subCategory: sub,
                          products: sectionProducts,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Product> _applyFilter(List<Product> products, CatalogFilter filter) {
    var result = products;
    if (filter.inStockOnly) {
      result = result.where((p) => !(p.displayVariant?.isOutOfStock ?? false)).toList();
    }
    switch (filter.sort) {
      case CatalogSort.relevance:
        break;
      case CatalogSort.priceLowToHigh:
        result = [...result]
          ..sort((a, b) => (a.displayVariant?.currentPrice ?? 0).compareTo(b.displayVariant?.currentPrice ?? 0));
      case CatalogSort.priceHighToLow:
        result = [...result]
          ..sort((a, b) => (b.displayVariant?.currentPrice ?? 0).compareTo(a.displayVariant?.currentPrice ?? 0));
      case CatalogSort.newest:
        result = [...result]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return result;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final filter = ref.watch(catalogFilterProvider(widget.categoryId));
            final notifier = ref.read(catalogFilterProvider(widget.categoryId).notifier);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter & Sort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton(
                          onPressed: () => notifier.state = const CatalogFilter(),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const Text('Sort by'),
                    ...CatalogSort.values.map(
                      (sort) => RadioListTile<CatalogSort>(
                        title: Text(_sortLabel(sort)),
                        value: sort,
                        groupValue: filter.sort,
                        onChanged: (value) => notifier.state = filter.copyWith(sort: value),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('In Stock Only'),
                      value: filter.inStockOnly,
                      onChanged: (value) => notifier.state = filter.copyWith(inStockOnly: value),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _sortLabel(CatalogSort sort) => switch (sort) {
        CatalogSort.relevance => 'Relevance (default)',
        CatalogSort.priceLowToHigh => 'Price: Low to High',
        CatalogSort.priceHighToLow => 'Price: High to Low',
        CatalogSort.newest => 'Newest First',
      };
}

class _SubCategorySection extends StatelessWidget {
  const _SubCategorySection({super.key, required this.subCategory, required this.products});

  final SubCategory subCategory;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subCategory.name, style: Theme.of(context).textTheme.titleMedium),
              Text('${products.length}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Coming soon — check back later!'),
          )
        else
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.45,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => ProductTile(product: products[index]),
          ),
      ],
    );
  }
}
