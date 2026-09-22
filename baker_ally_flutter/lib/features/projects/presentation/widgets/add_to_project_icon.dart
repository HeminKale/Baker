import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/login_required_sheet.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../providers/project_providers.dart';
import 'add_to_project_dialog.dart';

/// Placed wherever `WishlistHeart` is today -- product tile + detail
/// (07_projects.md §3). Unlike the heart, this isn't a binary toggle (a
/// product can belong to zero, one, or several projects), but it still gives
/// instant filled/outline feedback via the flattened
/// `projectItemVariantIdsProvider` set.
class AddToProjectIcon extends ConsumerWidget {
  const AddToProjectIcon({
    super.key,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.currentPrice,
    this.imageUrl,
  });

  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final int currentPrice;
  final String? imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInAProject = ref.watch(projectItemVariantIdsProvider).contains(variantId);

    return IconButton(
      icon: Icon(
        isInAProject ? Icons.folder_special : Icons.folder_special_outlined,
        color: isInAProject ? Theme.of(context).colorScheme.primary : null,
      ),
      onPressed: () {
        if (!ref.read(authProvider).isLoggedIn) {
          showLoginRequiredSheet(context);
          return;
        }
        AddToProjectDialog.show(
          context,
          variantId: variantId,
          productId: productId,
          productName: productName,
          variantName: variantName,
          currentPrice: currentPrice,
          imageUrl: imageUrl,
        );
      },
    );
  }
}
