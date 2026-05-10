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
    try {
      final token = await _sessionStore.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Error al leer token de sesion: $e',
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _sessionStore.clearSession();
    }
    handler.next(err);
  }
}
