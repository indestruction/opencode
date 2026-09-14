import 'dart:convert';

import 'package:opencode/core/errors/failures.dart';
import 'package:opencode/data/ai/http_stream_client.dart';
import 'package:opencode/domain/ai/ai_prompt_composer.dart';
import 'package:opencode/domain/ai/base_ai_provider.dart';
import 'package:opencode/domain/entities/ai_completion_request.dart';
import 'package:opencode/domain/entities/ai_message.dart';
import 'package:opencode/domain/entities/ai_stream_event.dart';

final class OpenRouterProvider extends BaseAiProvider {
  OpenRouterProvider(super.config, {HttpStreamClient? client})
    : _http = client ?? HttpStreamClient();

  static const String defaultBaseUrl = 'https://openrouter.ai/api/v1';
  static const String _referrer = 'https://github.com/opencode-mobile/opencode';

  final HttpStreamClient _http;

  String get _baseUrl {
    final String raw = config.baseUrl.trim();
    final String value = raw.isEmpty ? defaultBaseUrl : raw;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  @override
  Stream<AiStreamEvent> streamChat(AiCompletionRequest request) async* {
    final String? apiKey = config.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      yield const AiErrorEvent('OpenRouter API key is not configured');
      return;
    }

    try {
      final List<AiMessage> messages = AiPromptComposer.compose(request);

      final Stream<String> lines = _http.postJsonLines(
        uri: Uri.parse('$_baseUrl/chat/completions'),
        headers: <String, String>{
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': _referrer,
          'X-Title': 'Opencode',
        },
        body: <String, dynamic>{
          'model': request.model ?? config.defaultModel,
          'messages': <Map<String, dynamic>>[
            for (final message in messages) message.toOpenAiJson(),
          ],
          'stream': true,
          if (request.temperature != null) 'temperature': request.temperature,
          if (request.maxTokens != null) 'max_tokens': request.maxTokens,
        },
      );

      await for (final String line in lines) {
        final AiStreamEvent? event = _parseSseLine(line);
        if (event != null) {
          yield event;
        }
        if (event is AiDoneEvent) {
          return;
        }
      }
    } on Failure catch (failure) {
      yield AiErrorEvent(failure.message);
    } on Object catch (error) {
      yield AiErrorEvent(error.toString());
    }
  }

  AiStreamEvent? _parseSseLine(String line) {
    if (line.isEmpty || line.startsWith(':')) {
      return null;
    }
    if (!line.startsWith('data:')) {
      return null;
    }

    final String payload = line.substring(5).trim();
    if (payload == '[DONE]') {
      return const AiDoneEvent('stop');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(payload) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }

    final List<dynamic>? choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      return null;
    }

    final Map<String, dynamic> choice = choices.first as Map<String, dynamic>;
    final Map<String, dynamic>? delta = choice['delta'] as Map<String, dynamic>?;
    final String? content = delta?['content'] as String?;
    if (content != null && content.isNotEmpty) {
      return AiDeltaEvent(content);
    }

    final String? finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) {
      return AiDoneEvent(finishReason);
    }
    return null;
  }

  @override
  Future<List<String>> listModels() async {
    final Map<String, dynamic> json = await _http.getJson(
      uri: Uri.parse('$_baseUrl/models'),
    );
    final List<dynamic> data = json['data'] as List<dynamic>? ?? const <dynamic>[];
    return <String>[
      for (final model in data) (model as Map<String, dynamic>)['id'] as String,
    ];
  }

  @override
  Future<bool> healthCheck() async {
    if (!config.hasApiKey) {
      return false;
    }
    try {
      await listModels();
      return true;
    } on Object {
      return false;
    }
  }
}
