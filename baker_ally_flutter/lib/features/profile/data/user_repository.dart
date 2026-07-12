import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/user_profile.dart';

/// GET/PATCH /v1/users/me. Avatar upload goes directly Flutter -> Supabase
/// Storage (06_profile_and_account.md's Data & API table: "Upload avatar |
/// Supabase Storage direct upload | —"), not proxied through Hono. Network
/// -only -- profile isn't part of the offline story.
class UserRepository {
  UserRepository({required Dio dio, required SupabaseClient supabase})
      : _dio = dio,
        _supabase = supabase;

  final Dio _dio;
  final SupabaseClient _supabase;

  Future<UserProfile> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/users/me');
    return UserProfile.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateMe({
    String? fullName,
    String? businessName,
    String? gstin,
    String? avatarUrl,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v1/users/me',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (businessName != null) 'businessName': businessName,
        if (gstin != null) 'gstin': gstin,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    return (response.data!['data'] as Map<String, dynamic>)['user'] as Map<String, dynamic>;
  }

  /// Uploads to `avatars/{userId}.webp` (public bucket, Key Rules), overwriting
  /// any previous avatar, and returns its public URL for the caller to PATCH
  /// onto `users.avatar_url`.
  Future<String> uploadAvatar(String userId, Uint8List bytes) async {
    final path = '$userId.webp';
    await _supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/webp'),
        );
    return _supabase.storage.from('avatars').getPublicUrl(path);
  }
}
