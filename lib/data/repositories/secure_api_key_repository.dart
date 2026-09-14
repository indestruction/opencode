import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencode/domain/repositories/api_key_repository.dart';

final class SecureApiKeyRepository implements ApiKeyRepository {
  SecureApiKeyRepository({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String providerId) => _storage.read(key: _key(providerId));

  @override
  Future<void> write(String providerId, String apiKey) =>
      _storage.write(key: _key(providerId), value: apiKey);

  @override
  Future<void> delete(String providerId) => _storage.delete(key: _key(providerId));

  static String _key(String providerId) => 'ai_provider.$providerId.api_key';
}
