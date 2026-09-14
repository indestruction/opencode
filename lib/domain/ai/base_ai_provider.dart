import 'package:opencode/core/errors/failures.dart';
import 'package:opencode/domain/entities/ai_completion.dart';
import 'package:opencode/domain/entities/ai_completion_request.dart';
import 'package:opencode/domain/entities/ai_provider_config.dart';
import 'package:opencode/domain/entities/ai_stream_event.dart';

abstract class BaseAiProvider {
  const BaseAiProvider(this.config);

  final AiProviderConfig config;

  Stream<AiStreamEvent> streamChat(AiCompletionRequest request);

  Future<AiCompletion> complete(AiCompletionRequest request) async {
    final StringBuffer buffer = StringBuffer();
    String? finishReason;

    await for (final AiStreamEvent event in streamChat(request)) {
      switch (event) {
        case AiDeltaEvent(:final String delta):
          buffer.write(delta);
        case AiDoneEvent():
          finishReason = event.finishReason;
        case AiErrorEvent(:final String message):
          throw ProviderFailure(message);
      }
    }

    return AiCompletion(text: buffer.toString(), finishReason: finishReason);
  }

  Future<List<String>> listModels();

  Future<bool> healthCheck();
}
