import '../../../catalog/data/models/product.dart';

/// Shape of GET /v1/home -- three top-10 preview lists, same Product shape as
/// GET /v1/products (01_home_tab.md §9).
class HomeSections {
  const HomeSections({required this.newlyLaunched, required this.newOffers, required this.trending});

  final List<Product> newlyLaunched;
  final List<Product> newOffers;
  final List<Product> trending;

  factory HomeSections.fromJson(Map<String, dynamic> json) {
    List<Product> parse(String key) =>
        (json[key] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    return HomeSections(
      newlyLaunched: parse('newlyLaunched'),
      newOffers: parse('newOffers'),
      trending: parse('trending'),
    );
  }
}

/// Section keys used across the repository, providers, and the "See all"
/// route -- also the Drift `CachedHomeSections.section` values.
enum HomeSection { newlyLaunched, newOffers, trending }

extension HomeSectionX on HomeSection {
  /// GET /v1/home/:slug path segment.
  String get apiSlug => switch (this) {
        HomeSection.newlyLaunched => 'newly-launched',
        HomeSection.newOffers => 'new-offers',
        HomeSection.trending => 'trending',
      };

  String get title => switch (this) {
        HomeSection.newlyLaunched => 'Newly Launched',
        HomeSection.newOffers => 'New Offers',
        HomeSection.trending => 'Trending Now',
      };
}

/// Reverse of [HomeSectionX.apiSlug] -- parses the `/home/section/:slug`
/// route parameter back into a [HomeSection].
HomeSection homeSectionFromSlug(String slug) {
  return HomeSection.values.firstWhere(
    (s) => s.apiSlug == slug,
    orElse: () => throw ArgumentError('Unknown home section slug: $slug'),
  );
}
