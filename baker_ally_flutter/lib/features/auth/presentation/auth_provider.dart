import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    supabase: ref.watch(supabaseClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
    dio: ref.watch(dioProvider),
  );
});

/// Root auth state (00_common_architecture.md §2). `isLoading` covers both
/// "checking for a restored session on cold start" and "sign-in in flight".
class AuthSessionState {
  const AuthSessionState({
    this.isLoggedIn = false,
    this.userId,
    this.role,
    this.isLoading = true,
  });

  final bool isLoggedIn;
  final String? userId;
  final String? role;
  final bool isLoading;

  AuthSessionState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? role,
    bool? isLoading,
  }) {
    return AuthSessionState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthSessionState> {
  AuthNotifier(this._repository) : super(const AuthSessionState()) {
    _subscription = _repository.onAuthStateChange.listen((_) => _sync());
    _sync();
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _subscription;

  Future<void> _sync() async {
    await _repository.syncSessionToStorage();
    final session = _repository.currentSession;

    if (session == null) {
      state = const AuthSessionState(isLoading: false);
      return;
    }

    state = state.copyWith(
      isLoggedIn: true,
      userId: session.user.id,
      isLoading: true,
    );

    try {
      final profile = await _repository.hydrateProfile();
      state = state.copyWith(role: profile['role'] as String?, isLoading: false);
    } catch (_) {
      // Backend unreachable -- still signed in against Supabase; role stays
      // unresolved until the next successful sync.
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signInWithGoogle() => _repository.signInWithGoogle();

  Future<void> sendEmailOtp(String email) => _repository.sendEmailOtp(email);

  Future<void> verifyEmailOtp({required String email, required String token}) =>
      _repository.verifyEmailOtp(email: email, token: token);

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthSessionState(isLoading: false);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthSessionState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
