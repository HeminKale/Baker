import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/login_required_sheet.dart';
import '../../../auth/presentation/auth_provider.dart';

/// Sits beside the avatar in `app_shell.dart`'s `_TopBar` (07_projects.md
/// §2). Opens the full Projects list. Same login-gating as the avatar/heart.
class ProjectsTopBarIcon extends ConsumerWidget {
  const ProjectsTopBarIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.folder_special_outlined),
      tooltip: 'Your Projects',
      onPressed: () {
        if (!ref.read(authProvider).isLoggedIn) {
          showLoginRequiredSheet(context);
          return;
        }
        context.push('/projects');
      },
    );
  }
}
