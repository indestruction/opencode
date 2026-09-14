enum AiMessageRole { system, user, assistant }

final class AiMessage {
  const AiMessage({required this.role, required this.content});

  factory AiMessage.system(String content) =>
      AiMessage(role: AiMessageRole.system, content: content);

  factory AiMessage.user(String content) =>
      AiMessage(role: AiMessageRole.user, content: content);

  factory AiMessage.assistant(String content) =>
      AiMessage(role: AiMessageRole.assistant, content: content);

  final AiMessageRole role;
  final String content;

  Map<String, dynamic> toOpenAiJson() => <String, dynamic>{
    'role': role.name,
    'content': content,
  };

  AiMessage copyWith({String? content}) =>
      AiMessage(role: role, content: content ?? this.content);
}
