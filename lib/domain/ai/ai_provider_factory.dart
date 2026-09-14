import 'package:opencode/core/errors/failures.dart';
import 'package:opencode/domain/ai/base_ai_provider.dart';
import 'package:opencode/domain/entities/ai_provider_config.dart';

typedef AiProviderBuilder = BaseAiProvider Function(AiProviderConfig config);

final class AiProviderFactory {
  AiProviderFactory._();

  static final Map<AiProviderKind, AiProviderBuilder> _builders =
      <AiProviderKind, AiProviderBuilder>{};

  static void register(AiProviderKind kind, AiProviderBuilder builder) {
    _builders[kind] = builder;
  }

  static void registerAll(Map<AiProviderKind, AiProviderBuilder> builders) {
    _builders.addAll(builders);
  }

  static bool isRegistered(AiProviderKind kind) => _builders.containsKey(kind);

  static Iterable<AiProviderKind> get registeredKinds =>
      List<AiProviderKind>.unmodifiable(_builders.keys);

  static BaseAiProvider create(AiProviderConfig config) {
    final AiProviderBuilder? builder = _builders[config.kind];
    if (builder == null) {
      throw ConfigFailure(
        'AI provider "${config.kind.name}" is not registered',
      );
    }
    return builder(config);
  }

  static void clearRegistrations() => _builders.clear();
}
