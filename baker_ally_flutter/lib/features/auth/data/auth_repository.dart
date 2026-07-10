import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/secure_storage.dart';

/// The only place in the app allowed to touch supabase_flutter directly --
/// auth only, per backend_stack.md §15 ("What it does NOT do in Baker Ally").
/// Everything else (profile, cart, orders...) goes through Dio -> Hono.
class AuthRepository {
  AuthRepository({
    required SupabaseClient supabase,
    required SecureStorage secureStorage,
    required Dio dio,
  })  : _supabase = supabase,
        _secureStorage = secureStorage,
        _dio = dio;

  final SupabaseClient _supabase;
  final SecureStorage _secureStorage;
  final Dio _dio;

  /// Emits on every Supabase auth event (sign-in, sign-out, token refresh).
  /// Deliberately erased to `void` -- consumers re-read `currentSession`
  /// fresh rather than trusting the event payload, keeping this the single
  /// seam that knows about supabase_flutter's own types.
  Stream<void> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange.map((_) {});

  Session? get currentSession => _supabase.auth.currentSession;

  Future<void> signInWithGoogle() {
    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.chefsandbakers.app://login-callback',
    );
  }

  /// Sends a 6-digit OTP code to [email] (Supabase's email OTP template,
  /// not a magic link). Second sign-in path alongside Google -- no Google
  /// Cloud OAuth client required.
  Future<void> sendEmailOtp(String email) {
    return _supabase.auth.signInWithOtp(email: email);
  }

  /// Verifies the code sent by [sendEmailOtp]. On success, Supabase sets
  /// the session, which fires `onAuthStateChange` same as the Google flow.
  Future<void> verifyEmailOtp({required String email, required String token}) {
    return _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  /// Mirrors the current session's access token into secure storage so Dio's
  /// interceptor always reads from one consistent place (Phase 1.1/1.4).
  /// Call after every auth state change, including token refresh.
  Future<void> syncSessionToStorage() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _secureStorage.writeJwt(session.accessToken);
    } else {
      await _secureStorage.clearJwt();
    }
  }

  /// Signup-hook replacement (Phase 1.5): idempotently creates the
  /// public.users row with the default role on first call, returns
  /// {user, role} either way.
  Future<Map<String, dynamic>> hydrateProfile() async {
    final response = await _dio.post<Map<String, dynamic>>('/v1/auth/me');
    return response.data!['data'] as Map<String, dynamic>;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _secureStorage.clearJwt();
  }
}
