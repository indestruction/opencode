import 'package:opencode/data/ai/providers/ollama_provider.dart';
import 'package:opencode/data/ai/providers/openrouter_provider.dart';
import 'package:opencode/domain/ai/ai_provider_factory.dart';
import 'package:opencode/domain/entities/ai_provider_config.dart';

abstract final class AiProviderBootstrap {
  static bool _initialized = false;

  static void ensureRegistered() {
    if (_initialized) {
      return;
    }

    AiProviderFactory.registerAll(<AiProviderKind, AiProviderBuilder>{
      AiProviderKind.openRouter: (config) => OpenRouterProvider(config),
      AiProviderKind.ollama: (config) => OllamaProvider(config),
    });

    _initialized = true;
  }
}
