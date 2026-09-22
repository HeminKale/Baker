import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/models/project.dart';
import '../../data/models/project_detail.dart';
import '../../data/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(dio: ref.watch(dioProvider), db: ref.watch(appDatabaseProvider));
});

/// Full list for the /projects screen, tab-filtered client-side from one
/// fetch -- autoDispose so it doesn't serve stale items next login (matches
/// `wishlistItemsProvider`'s precedent).
final projectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  return ref.watch(projectRepositoryProvider).getAll();
});

/// One project's items + totals, for /projects/:id.
final projectDetailProvider = FutureProvider.autoDispose.family<ProjectDetail, String>((ref, projectId) async {
  return ref.watch(projectRepositoryProvider).getDetail(projectId);
});

/// O(1) lookup for the on-product icon's filled/outline state (§3) -- same
/// role `wishlistIdsProvider` plays for the heart. Seeded from the Drift
/// cache immediately, then refreshed from the server.
class ProjectItemIdsNotifier extends StateNotifier<Set<String>> {
  ProjectItemIdsNotifier(this._repository) : super(const {}) {
    _init();
  }

  final ProjectRepository _repository;

  Future<void> _init() async {
    state = await _repository.getCachedItemVariantIds();
    try {
      state = await _repository.refreshItemVariantIds();
    } catch (_) {
      // Offline or logged out -- keep whatever was cached locally.
    }
  }

  Future<void> refresh() async {
    try {
      state = await _repository.refreshItemVariantIds();
    } catch (_) {
      // Offline -- keep current state.
    }
  }
}

final projectItemVariantIdsProvider = StateNotifierProvider<ProjectItemIdsNotifier, Set<String>>((ref) {
  return ProjectItemIdsNotifier(ref.watch(projectRepositoryProvider));
});
