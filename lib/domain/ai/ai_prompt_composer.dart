import 'package:opencode/domain/entities/ai_completion_request.dart';
import 'package:opencode/domain/entities/ai_message.dart';

abstract final class AiPromptComposer {
  static List<AiMessage> compose(AiCompletionRequest request) {
    if (request.contextFiles.isEmpty) {
      return request.messages;
    }

    final StringBuffer buffer = StringBuffer()
      ..writeln('You are an AI coding agent embedded in the Opencode mobile IDE.')
      ..writeln('The user is currently editing the following files:')
      ..writeln();

    for (final file in request.contextFiles) {
      buffer.writeln(file.toPromptBlock());
    }

    return <AiMessage>[
      AiMessage.system(buffer.toString()),
      ...request.messages,
    ];
  }
}
