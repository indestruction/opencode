enum AiProviderKind { openRouter, ollama }

final class AiProviderConfig {
  const AiProviderConfig({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.baseUrl,
    required this.defaultModel,
    this.apiKey,
    this.isLocal = false,
    this.models = const <String>[],
  });

  final String id;
  final AiProviderKind kind;
  final String displayName;
  final String baseUrl;
  final String defaultModel;
  final String? apiKey;
  final bool isLocal;
  final List<String> models;

  bool get requiresApiKey => !isLocal;

  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;

  AiProviderConfig withApiKey(String? apiKey) => AiProviderConfig(
    id: id,
    kind: kind,
    displayName: displayName,
    baseUrl: baseUrl,
    defaultModel: defaultModel,
    apiKey: apiKey,
    isLocal: isLocal,
    models: models,
  );

  AiProviderConfig copyWith({
    String? baseUrl,
    String? defaultModel,
    List<String>? models,
  }) => AiProviderConfig(
    id: id,
    kind: kind,
    displayName: displayName,
    baseUrl: baseUrl ?? this.baseUrl,
    defaultModel: defaultModel ?? this.defaultModel,
    apiKey: apiKey,
    isLocal: isLocal,
    models: models ?? this.models,
  );
}
