import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencode/di/injector.dart';
import 'package:opencode/domain/entities/ai_completion_request.dart';
import 'package:opencode/domain/entities/ai_context_file.dart';
import 'package:opencode/domain/entities/ai_message.dart';
import 'package:opencode/domain/entities/ai_stream_event.dart';
import 'package:opencode/presentation/providers/editor_tabs_controller.dart';

final class ChatEntry {
  const ChatEntry({required this.message, this.streaming = false});

  final AiMessage message;
  final bool streaming;

  ChatEntry copyWith({AiMessage? message, bool? streaming}) => ChatEntry(
    message: message ?? this.message,
    streaming: streaming ?? this.streaming,
  );
}

final class AiChatState {
  const AiChatState({
    this.entries = const <ChatEntry>[],
    this.isBusy = false,
    this.error,
  });

  final List<ChatEntry> entries;
  final bool isBusy;
  final String? error;

  AiChatState copyWith({
    List<ChatEntry>? entries,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) => AiChatState(
    entries: entries ?? this.entries,
    isBusy: isBusy ?? this.isBusy,
    error: clearError ? null : (error ?? this.error),
  );
}

final class AiChatController extends Notifier<AiChatState> {
  @override
  AiChatState build() => const AiChatState();

  Future<void> send(String prompt) async {
    final String trimmed = prompt.trim();
    if (trimmed.isEmpty || state.isBusy) {
      return;
    }

    state = state.copyWith(
      entries: <ChatEntry>[
        ...state.entries,
        ChatEntry(message: AiMessage.user(trimmed)),
        ChatEntry(message: AiMessage.assistant(''), streaming: true),
      ],
      isBusy: true,
      clearError: true,
    );

    try {
      final provider = await ref.read(activeAiProviderProvider.future);
      final EditorTabsState tabsState = ref.read(editorTabsControllerProvider);

      final List<AiContextFile> contextFiles = <AiContextFile>[
        for (final EditorTab tab in tabsState.tabs)
          AiContextFile(
            path: tab.path,
            language: tab.language,
            content: tab.content,
          ),
      ];

      final List<AiMessage> history = <AiMessage>[
        for (final ChatEntry entry in state.entries)
          if (entry.message.content.isNotEmpty) entry.message,
      ];

      final AiCompletionRequest request = AiCompletionRequest(
        messages: history,
        contextFiles: contextFiles,
      );

      await for (final AiStreamEvent event in provider.streamChat(request)) {
        switch (event) {
          case AiDeltaEvent(:final String delta):
            _appendDelta(delta);
          case AiDoneEvent():
            _markAnswered();
          case AiErrorEvent(:final String message):
            _fail(message);
        }
      }
    } on Object catch (error) {
      _fail(error.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void clear() => state = const AiChatState();

  void _appendDelta(String delta) =>
      _updateLastAssistant((current) => current + delta);

  void _markAnswered() =>
      _updateLastAssistant((current) => current, streaming: false);

  void _fail(String message) {
    _updateLastAssistant((current) => current, streaming: false);
    state = state.copyWith(error: message);
  }

  void _updateLastAssistant(
    String Function(String current) transform, {
    bool? streaming,
  }) {
    final int lastIndex = state.entries.lastIndexWhere(
      (entry) => entry.message.role == AiMessageRole.assistant,
    );
    if (lastIndex < 0) {
      return;
    }

    final List<ChatEntry> entries = <ChatEntry>[...state.entries];
    final ChatEntry entry = entries[lastIndex];
    entries[lastIndex] = entry.copyWith(
      message: AiMessage.assistant(transform(entry.message.content)),
      streaming: streaming ?? entry.streaming,
    );
    state = state.copyWith(entries: entries);
  }
}

final NotifierProvider<AiChatController, AiChatState> aiChatControllerProvider =
    NotifierProvider<AiChatController, AiChatState>(AiChatController.new);
