import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/models/user_profile.dart';
import '../../data/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(dio: ref.watch(dioProvider), supabase: ref.watch(supabaseClientProvider));
});

/// GET /v1/users/me -- backs the top bar avatar, Profile Overlay and Edit
/// Profile screen. `autoDispose` so a logout (which stops the top bar from
/// watching this while logged out) clears any stale cached profile before
/// the next login. Refresh after an edit via `ref.invalidate(profileProvider)`
/// (same pattern `AddressSelectorSheet` uses for `addressesProvider`).
final profileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  return ref.watch(userRepositoryProvider).getMe();
});
