import 'package:flutter/material.dart';
import 'package:opencode/domain/entities/code_token.dart';
import 'package:opencode/domain/entities/editor_language.dart';
import 'package:opencode/presentation/editor/editor_syntax_theme.dart';

final class CodeEditingController extends TextEditingController {
  CodeEditingController({
    required String text,
    required this.language,
    List<CodeToken> tokens = const <CodeToken>[],
  }) : _tokens = tokens,
       super(text: text);

  EditorLanguage language;

  List<CodeToken> _tokens;

  List<CodeToken> get tokens => _tokens;

  set tokens(List<CodeToken> value) {
    _tokens = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextStyle base = style ?? const TextStyle();
    final int length = text.length;
    final List<InlineSpan> spans = <InlineSpan>[];

    int cursor = 0;
    for (final CodeToken token in _tokens) {
      if (token.start < cursor || token.start >= length) {
        continue;
      }
      if (token.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, token.start), style: base));
      }
      final int end = token.end.clamp(cursor, length).toInt();
      spans.add(
        TextSpan(
          text: text.substring(token.start, end),
          style: base.copyWith(color: EditorSyntaxTheme.colorFor(token.type)),
        ),
      );
      cursor = end;
    }

    if (cursor < length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }

    return TextSpan(style: base, children: spans);
  }
}
