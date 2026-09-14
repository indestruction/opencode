import 'package:opencode/domain/entities/ai_context_file.dart';
import 'package:opencode/domain/entities/ai_message.dart';

final class AiCompletionRequest {
  const AiCompletionRequest({
    required this.messages,
    this.contextFiles = const <AiContextFile>[],
    this.model,
    this.temperature,
    this.maxTokens,
  });

  final List<AiMessage> messages;
  final List<AiContextFile> contextFiles;
  final String? model;
  final double? temperature;
  final int? maxTokens;

  bool get hasContext => contextFiles.isNotEmpty;
}
