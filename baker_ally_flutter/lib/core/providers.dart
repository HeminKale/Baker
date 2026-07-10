import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/local_db/app_database.dart';
import 'network/dio_client.dart';
import 'storage/secure_storage.dart';

/// Root providers -- alive for the app's lifetime (00_common_architecture.md
/// §2, "Riverpod State Architecture"). Feature-specific root providers
/// (authProvider, cartProvider, ...) live in their own feature folders and
/// build on top of these.

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final dioProvider = Provider<Dio>((ref) {
  return buildDioClient(ref.watch(secureStorageProvider));
});

/// Single Drift instance for the app's lifetime -- catalog cache (Phase 2)
/// and wishlist cache both read/write through this.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
