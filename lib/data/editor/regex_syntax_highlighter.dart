import 'package:opencode/data/editor/syntax_grammars.dart';
import 'package:opencode/domain/editor/syntax_highlighter.dart';
import 'package:opencode/domain/entities/code_token.dart';
import 'package:opencode/domain/entities/editor_language.dart';

final class RegexSyntaxHighlighter implements SyntaxHighlighter {
  const RegexSyntaxHighlighter();

  static const String _operatorChars = '+-*/%=!<>&|^~?';
  static const String _punctuationChars = '(){}[],.;:@#\\';

  @override
  List<CodeToken> tokenize({
    required String source,
    required EditorLanguage language,
  }) {
    final SyntaxGrammar grammar = SyntaxGrammars.of(language);
    final List<CodeToken> tokens = <CodeToken>[];
    final int length = source.length;
    int i = 0;

    while (i < length) {
      final String ch = source[i];

      if (_isWhitespace(ch)) {
        i++;
        continue;
      }

      final int? blockEnd = _matchBlockComment(source, i, grammar);
      if (blockEnd != null) {
        tokens.add(CodeToken(start: i, end: blockEnd, type: CodeTokenType.comment));
        i = blockEnd;
        continue;
      }

      final int? lineEnd = _matchLineComment(source, i, grammar);
      if (lineEnd != null) {
        tokens.add(CodeToken(start: i, end: lineEnd, type: CodeTokenType.comment));
        i = lineEnd;
        continue;
      }

      final int? stringEnd = _matchString(source, i, grammar);
      if (stringEnd != null) {
        tokens.add(CodeToken(start: i, end: stringEnd, type: CodeTokenType.string));
        i = stringEnd;
        continue;
      }

      if (ch == '@' && i + 1 < length && _isIdentifierStart(source[i + 1])) {
        final int end = _consumeIdentifier(source, i + 1);
        tokens.add(CodeToken(start: i, end: end, type: CodeTokenType.annotation));
        i = end;
        continue;
      }

      if (_isDigit(ch)) {
        final int end = _consumeNumber(source, i);
        tokens.add(CodeToken(start: i, end: end, type: CodeTokenType.number));
        i = end;
        continue;
      }

      if (_isIdentifierStart(ch)) {
        final int end = _consumeIdentifier(source, i);
        final String word = source.substring(i, end);
        tokens.add(
          CodeToken(
            start: i,
            end: end,
            type: _classify(word, source, end, grammar),
          ),
        );
        i = end;
        continue;
      }

      if (_operatorChars.contains(ch)) {
        tokens.add(CodeToken(start: i, end: i + 1, type: CodeTokenType.operator));
        i++;
        continue;
      }

      tokens.add(
        CodeToken(
          start: i,
          end: i + 1,
          type: _punctuationChars.contains(ch)
              ? CodeTokenType.punctuation
              : CodeTokenType.plain,
        ),
      );
      i++;
    }

    return tokens;
  }

  int? _matchBlockComment(String source, int i, SyntaxGrammar grammar) {
    final String? start = grammar.blockCommentStart;
    final String? end = grammar.blockCommentEnd;
    if (start == null || end == null || !source.startsWith(start, i)) {
      return null;
    }
    final int endIndex = source.indexOf(end, i + start.length);
    return endIndex < 0 ? source.length : endIndex + end.length;
  }

  int? _matchLineComment(String source, int i, SyntaxGrammar grammar) {
    for (final String prefix in grammar.lineComments) {
      if (prefix.isNotEmpty && source.startsWith(prefix, i)) {
        final int endIndex = source.indexOf('\n', i);
        return endIndex < 0 ? source.length : endIndex;
      }
    }
    return null;
  }

  int? _matchString(String source, int i, SyntaxGrammar grammar) {
    final int length = source.length;
    String delimiter = source[i];
    int contentStart = i + 1;

    if (grammar.rawStringPrefixes.contains(delimiter) &&
        i + 1 < length &&
        grammar.stringDelimiters.contains(source[i + 1])) {
      delimiter = source[i + 1];
      contentStart = i + 2;
      return _scanString(source, contentStart, delimiter, raw: true);
    }

    if (!grammar.stringDelimiters.contains(delimiter)) {
      return null;
    }

    if (grammar.tripleQuotedStrings &&
        i + 2 < length &&
        source[i + 1] == delimiter &&
        source[i + 2] == delimiter) {
      final String triple = delimiter * 3;
      final int endIndex = source.indexOf(triple, i + 3);
      return endIndex < 0 ? length : endIndex + 3;
    }

    return _scanString(source, contentStart, delimiter, raw: false);
  }

  int _scanString(
    String source,
    int start,
    String delimiter, {
    required bool raw,
  }) {
    final int length = source.length;
    int i = start;
    while (i < length) {
      final String ch = source[i];
      if (ch == '\n' && delimiter != '`') {
        return i;
      }
      if (!raw && ch == '\\') {
        i += 2;
        continue;
      }
      if (ch == delimiter) {
        return i + 1;
      }
      i++;
    }
    return length;
  }

  int _consumeNumber(String source, int i) {
    final int length = source.length;
    int j = i;
    bool previousWasExponent = false;
    while (j < length) {
      final String ch = source[j];
      if (_isDigit(ch) ||
          ch == '.' ||
          ch == '_' ||
          ch == 'x' ||
          ch == 'X' ||
          ch == 'o' ||
          ch == 'O' ||
          ch == 'b' ||
          ch == 'B' ||
          _isHexLetter(ch)) {
        previousWasExponent = ch == 'e' || ch == 'E';
        j++;
        continue;
      }
      if ((ch == '+' || ch == '-') && previousWasExponent) {
        previousWasExponent = false;
        j++;
        continue;
      }
      break;
    }
    return j;
  }

  int _consumeIdentifier(String source, int i) {
    final int length = source.length;
    int j = i;
    while (j < length && _isIdentifierPart(source[j])) {
      j++;
    }
    return j;
  }

  CodeTokenType _classify(
    String word,
    String source,
    int end,
    SyntaxGrammar grammar,
  ) {
    if (grammar.keywords.contains(word)) {
      return CodeTokenType.keyword;
    }
    if (grammar.types.contains(word)) {
      return CodeTokenType.type;
    }
    if (grammar.constants.contains(word)) {
      return CodeTokenType.constant;
    }
    if (_isConstantLike(word)) {
      return CodeTokenType.constant;
    }
    if (grammar.functionBeforeParen && _nextNonSpaceIsOpenParen(source, end)) {
      return CodeTokenType.function;
    }
    return CodeTokenType.identifier;
  }

  bool _nextNonSpaceIsOpenParen(String source, int from) {
    final int length = source.length;
    int j = from;
    while (j < length && (source[j] == ' ' || source[j] == '\t')) {
      j++;
    }
    return j < length && source[j] == '(';
  }

  bool _isConstantLike(String word) {
    if (word.length < 2) {
      return false;
    }
    for (int i = 0; i < word.length; i++) {
      final String ch = word[i];
      if (ch == '_' || _isDigit(ch)) {
        continue;
      }
      if (ch != ch.toUpperCase() || ch == ch.toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  bool _isWhitespace(String ch) =>
      ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r';

  bool _isDigit(String ch) =>
      ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39;

  bool _isHexLetter(String ch) {
    final int code = ch.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x46) || (code >= 0x61 && code <= 0x66);
  }

  bool _isIdentifierStart(String ch) {
    final int code = ch.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5A) ||
        (code >= 0x61 && code <= 0x7A) ||
        ch == '_' ||
        ch == r'$';
  }

  bool _isIdentifierPart(String ch) => _isIdentifierStart(ch) || _isDigit(ch);
}
