import 'package:flutter/foundation.dart';
import 'package:opencode/data/editor/regex_syntax_highlighter.dart';
import 'package:opencode/domain/entities/code_token.dart';
import 'package:opencode/domain/entities/editor_language.dart';

final class HighlightJob {
  const HighlightJob(this.source, this.language);

  final String source;
  final EditorLanguage language;
}

List<CodeToken> _tokenizeInIsolate(HighlightJob job) =>
    const RegexSyntaxHighlighter().tokenize(
      source: job.source,
      language: job.language,
    );

final class EditorHighlightService {
  EditorHighlightService({RegexSyntaxHighlighter? highlighter})
    : _highlighter = highlighter ?? const RegexSyntaxHighlighter();

  static const int isolateThreshold = 16000;

  final RegexSyntaxHighlighter _highlighter;

  Future<List<CodeToken>> highlight({
    required String source,
    required EditorLanguage language,
  }) {
    if (source.length < isolateThreshold) {
      return Future<List<CodeToken>>.value(
        _highlighter.tokenize(source: source, language: language),
      );
    }
    return compute(_tokenizeInIsolate, HighlightJob(source, language));
  }
}
