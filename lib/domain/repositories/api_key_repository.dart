abstract interface class ApiKeyRepository {
  Future<String?> read(String providerId);

  Future<void> write(String providerId, String apiKey);

  Future<void> delete(String providerId);
}
