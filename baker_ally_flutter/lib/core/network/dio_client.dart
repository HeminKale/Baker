import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';

/// Every request to our Hono backend goes through this client. Business data
/// (products, cart, orders, users) always flows Dio -> Hono, never directly
/// through supabase_flutter -- see backend_stack.md §5 and §6.
Dio buildDioClient(SecureStorage secureStorage) {
  final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final jwt = await secureStorage.readJwt();
        if (jwt != null) {
          options.headers['Authorization'] = 'Bearer $jwt';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
}
