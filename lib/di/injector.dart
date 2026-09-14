import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencode/data/ai/providers/ollama_provider.dart';
import 'package:opencode/data/ai/providers/openrouter_provider.dart';
import 'package:opencode/data/repositories/secure_api_key_repository.dart';
import 'package:opencode/domain/ai/ai_provider_factory.dart';
import 'package:opencode/domain/ai/base_ai_provider.dart';
import 'package:opencode/domain/entities/ai_provider_config.dart';
import 'package:opencode/domain/repositories/api_key_repository.dart';

final Provider<ApiKeyRepository> apiKeyRepositoryProvider =
    Provider<ApiKeyRepository>((ref) => SecureApiKeyRepository());

final Provider<List<AiProviderConfig>> aiProviderConfigsProvider =
    Provider<List<AiProviderConfig>>((ref) {
      return const <AiProviderConfig>[
        AiProviderConfig(
          id: 'openrouter',
          kind: AiProviderKind.openRouter,
          displayName: 'OpenRouter',
          baseUrl: OpenRouterProvider.defaultBaseUrl,
          defaultModel: 'anthropic/claude-sonnet-4.5',
        ),
        AiProviderConfig(
          id: 'ollama',
          kind: AiProviderKind.ollama,
          displayName: 'Ollama (local)',
          baseUrl: OllamaProvider.defaultBaseUrl,
          defaultModel: 'qwen2.5-coder:7b',
          isLocal: true,
        ),
      ];
    });

final StateProvider<String> activeAiProviderIdProvider =
    StateProvider<String>((ref) => 'openrouter');

final Provider<AiProviderConfig> activeAiProviderConfigProvider =
    Provider<AiProviderConfig>((ref) {
      final List<AiProviderConfig> configs = ref.watch(
        aiProviderConfigsProvider,
      );
      final String activeId = ref.watch(activeAiProviderIdProvider);
      return configs.firstWhere(
        (config) => config.id == activeId,
        orElse: () => configs.first,
      );
    });

final FutureProvider<BaseAiProvider> activeAiProviderProvider =
    FutureProvider<BaseAiProvider>((ref) async {
      final AiProviderConfig config = ref.watch(activeAiProviderConfigProvider);
      final String? apiKey = await ref
          .watch(apiKeyRepositoryProvider)
          .read(config.id);
      return AiProviderFactory.create(config.withApiKey(apiKey));
    });
