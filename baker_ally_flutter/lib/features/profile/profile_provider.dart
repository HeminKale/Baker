import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';

part 'profile_provider.g.dart';

/// GET /v1/users/me (Phase 1.5). No screen reads this yet -- the Profile
/// Overlay UI is built in Phase 5 -- but the endpoint + provider exist now
/// per the Phase 1 API surface.
@riverpod
Future<Map<String, dynamic>> profile(ProfileRef ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Map<String, dynamic>>('/v1/users/me');
  return response.data!['data'] as Map<String, dynamic>;
}
