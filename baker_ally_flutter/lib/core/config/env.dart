import 'package:envied/envied.dart';

part 'env.g.dart';

/// Build-time config from `.env` (never commit real values -- see `.env.example`).
/// Only non-secret, client-safe values belong here: the anon key is meant to
/// be public (RLS/service-role boundaries protect data, not this key).
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL')
  static const String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static const String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _Env.apiBaseUrl;
}
