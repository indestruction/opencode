import 'package:opencode/domain/entities/code_token.dart';
import 'package:opencode/domain/entities/editor_language.dart';

abstract interface class SyntaxHighlighter {
  List<CodeToken> tokenize({
    required String source,
    required EditorLanguage language,
  });
}
