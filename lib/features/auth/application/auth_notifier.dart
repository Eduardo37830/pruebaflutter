import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/dio_client.dart';
import '../data/session_store.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<bool> build() async {
    final token = await ref.read(sessionStoreProvider).getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    final sessionStore = ref.read(sessionStoreProvider);

    try {
      final response = await ref
          .read(dioClientProvider)
          .post('/auth/login', data: {'email': email, 'password': password});

      final body = response.data;
      if (body is! Map) {
        throw Exception('Respuesta de login invalida');
      }

      final token = body['token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('No se recibio token de autenticacion');
      }

      final user = body['user'];
      final userId = user is Map ? _asInt(user['id']) : null;

      await sessionStore.saveToken(token);
      if (userId != null) {
        await sessionStore.saveUserId(userId);
      }
      state = const AsyncValue.data(true);
    } on DioException catch (error, st) {
      state = AsyncValue.error(_extractApiError(error), st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await ref.read(sessionStoreProvider).clearSession();
    state = const AsyncValue.data(false);
  }

  String _extractApiError(DioException error) {
    final responseBody = error.response?.data;
    if (responseBody is Map) {
      final known = responseBody['error'] ?? responseBody['message'];
      if (known is String && known.isNotEmpty) {
        return known;
      }
    }

    return error.message ?? 'Error de conexion con el servidor';
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
