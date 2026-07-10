import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/sub_category.dart';
import 'shimmer_box.dart';

/// The tappable unit on Level 1 -- categories are just bold, non-tappable
/// headings (02_catalog_tab.md §2).
class SubcategoryTile extends StatelessWidget {
  const SubcategoryTile({super.key, required this.categoryId, required this.subCategory});

  final String categoryId;
  final SubCategory subCategory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: InkWell(
        onTap: () => context.push('/catalog/$categoryId/${subCategory.id}'),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: subCategory.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: subCategory.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerBox(),
                        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_outlined),
                      )
                    : const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subCategory.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
