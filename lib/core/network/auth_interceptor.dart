import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/session_store.dart';

part 'auth_interceptor.g.dart';

@riverpod
AuthInterceptor authInterceptor(AuthInterceptorRef ref) {
  return AuthInterceptor(ref.watch(sessionStoreProvider));
}

class AuthInterceptor extends Interceptor {
  final SessionStore _sessionStore;

  AuthInterceptor(this._sessionStore);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _sessionStore.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Manejar logica si el token expiró (redireccionamiento, deslogueo)
      _sessionStore.clearSession();
    }
    super.onError(err, handler);
  }
}
