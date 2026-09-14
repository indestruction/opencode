import 'dart:convert';

import 'package:opencode/core/errors/failures.dart';
import 'package:opencode/data/ai/http_stream_client.dart';
import 'package:opencode/domain/ai/ai_prompt_composer.dart';
import 'package:opencode/domain/ai/base_ai_provider.dart';
import 'package:opencode/domain/entities/ai_completion_request.dart';
import 'package:opencode/domain/entities/ai_message.dart';
import 'package:opencode/domain/entities/ai_stream_event.dart';

final class OllamaProvider extends BaseAiProvider {
  OllamaProvider(super.config, {HttpStreamClient? client})
    : _http = client ?? HttpStreamClient();

  static const String defaultBaseUrl = 'http://127.0.0.1:11434';

  final HttpStreamClient _http;

  String get _baseUrl {
    final String raw = config.baseUrl.trim();
    final String value = raw.isEmpty ? defaultBaseUrl : raw;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  @override
  Stream<AiStreamEvent> streamChat(AiCompletionRequest request) async* {
    try {
      final List<AiMessage> messages = AiPromptComposer.compose(request);

      final Stream<String> lines = _http.postJsonLines(
        uri: Uri.parse('$_baseUrl/api/chat'),
        body: <String, dynamic>{
          'model': request.model ?? config.defaultModel,
          'messages': <Map<String, dynamic>>[
            for (final message in messages) message.toOpenAiJson(),
          ],
          'stream': true,
          if (request.temperature != null)
            'options': <String, dynamic>{'temperature': request.temperature},
        },
      );

      await for (final String line in lines) {
        if (line.isEmpty) {
          continue;
        }

        final Map<String, dynamic> json;
        try {
          json = jsonDecode(line) as Map<String, dynamic>;
        } on FormatException {
          continue;
        }

        final String? error = json['error'] as String?;
        if (error != null) {
          yield AiErrorEvent(error);
          return;
        }

        final Map<String, dynamic>? message =
            json['message'] as Map<String, dynamic>?;
        final String? content = message?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          yield AiDeltaEvent(content);
        }

        if (json['done'] == true) {
          yield AiDoneEvent(json['done_reason'] as String?);
          return;
        }
      }
    } on Failure catch (failure) {
      yield AiErrorEvent(failure.message);
    } on Object catch (error) {
      yield AiErrorEvent(error.toString());
    }
  }

  @override
  Future<List<String>> listModels() async {
    final Map<String, dynamic> json = await _http.getJson(
      uri: Uri.parse('$_baseUrl/api/tags'),
    );
    final List<dynamic> models =
        json['models'] as List<dynamic>? ?? const <dynamic>[];
    return <String>[
      for (final model in models)
        (model as Map<String, dynamic>)['name'] as String,
    ];
  }

  @override
  Future<bool> healthCheck() async {
    try {
      await _http.getJson(uri: Uri.parse('$_baseUrl/api/version'));
      return true;
    } on Object {
      return false;
    }
  }
}
