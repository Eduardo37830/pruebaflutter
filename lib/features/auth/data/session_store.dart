import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_store.g.dart';

class SessionStore {
  final FlutterSecureStorage _storage;

  const SessionStore(this._storage);

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveUserId(int userId) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  Future<int?> getUserId() async {
    final rawValue = await _storage.read(key: _userIdKey);
    if (rawValue == null) {
      return null;
    }
    return int.tryParse(rawValue);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }
}

@riverpod
SessionStore sessionStore(SessionStoreRef ref) {
  return const SessionStore(
    FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
        storageCipherAlgorithm:
            StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
        accountName: 'escritor_app_session',
      ),
    ),
  );
}
