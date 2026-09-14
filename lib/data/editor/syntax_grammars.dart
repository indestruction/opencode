import 'package:opencode/domain/entities/editor_language.dart';

final class SyntaxGrammar {
  const SyntaxGrammar({
    this.keywords = const <String>{},
    this.types = const <String>{},
    this.constants = const <String>{},
    this.lineComments = const <String>['//'],
    this.blockCommentStart,
    this.blockCommentEnd,
    this.stringDelimiters = const <String>["'", '"'],
    this.tripleQuotedStrings = false,
    this.rawStringPrefixes = const <String>{'r'},
    this.caseSensitive = true,
    this.functionBeforeParen = true,
  });

  final Set<String> keywords;
  final Set<String> types;
  final Set<String> constants;
  final List<String> lineComments;
  final String? blockCommentStart;
  final String? blockCommentEnd;
  final List<String> stringDelimiters;
  final bool tripleQuotedStrings;
  final Set<String> rawStringPrefixes;
  final bool caseSensitive;
  final bool functionBeforeParen;
}

abstract final class SyntaxGrammars {
  static const Set<String> _dartKeywords = <String>{
    'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case',
    'catch', 'class', 'const', 'continue', 'covariant', 'default', 'deferred',
    'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension',
    'external', 'factory', 'final', 'finally', 'for', 'get', 'hide', 'if',
    'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
    'return', 'sealed', 'set', 'show', 'static', 'super', 'switch', 'sync',
    'this', 'throw', 'try', 'typedef', 'var', 'void', 'when', 'while', 'with',
    'yield', 'true', 'false',
  };

  static const Set<String> _dartTypes = <String>{
    'int', 'double', 'num', 'String', 'bool', 'List', 'Map', 'Set', 'Iterable',
    'Future', 'Stream', 'Object', 'Function', 'Widget', 'BuildContext',
    'State', 'StatefulWidget', 'StatelessWidget', 'Text', 'Container',
    'Color', 'Offset', 'Size', 'Duration', 'DateTime', 'ValueNotifier',
    'ChangeNotifier', 'TextEditingController', 'ScrollController',
  };

  static const Set<String> _jsKeywords = <String>{
    'async', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue',
    'debugger', 'default', 'delete', 'do', 'else', 'export', 'extends',
    'finally', 'for', 'from', 'function', 'get', 'if', 'import', 'in',
    'instanceof', 'let', 'new', 'of', 'return', 'set', 'static', 'super',
    'switch', 'this', 'throw', 'try', 'typeof', 'var', 'void', 'while',
    'with', 'yield', 'true', 'false', 'null', 'undefined',
  };

  static const Set<String> _tsTypes = <String>{
    'string', 'number', 'boolean', 'any', 'unknown', 'never', 'object',
    'symbol', 'bigint', 'interface', 'type', 'enum', 'namespace', 'declare',
    'readonly', 'keyof', 'infer', 'implements', 'private', 'protected',
    'public', 'abstract', 'as', 'satisfies', 'Promise', 'Array', 'Record',
  };

  static const Set<String> _pythonKeywords = <String>{
    'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue',
    'def', 'del', 'elif', 'else', 'except', 'finally', 'for', 'from',
    'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal', 'not', 'or',
    'pass', 'raise', 'return', 'try', 'while', 'with', 'yield', 'True',
    'False', 'None', 'self', 'match', 'case',
  };

  static const Set<String> _yamlKeywords = <String>{
    'true', 'false', 'null', 'yes', 'no', 'on', 'off',
  };

  static const Set<String> _shellKeywords = <String>{
    'if', 'then', 'else', 'elif', 'fi', 'for', 'while', 'do', 'done', 'case',
    'esac', 'function', 'in', 'select', 'until', 'export', 'local', 'return',
    'echo', 'cd', 'source', 'set', 'unset', 'readonly',
  };

  static const SyntaxGrammar _dart = SyntaxGrammar(
    keywords: _dartKeywords,
    types: _dartTypes,
    blockCommentStart: '/*',
    blockCommentEnd: '*/',
    tripleQuotedStrings: true,
    rawStringPrefixes: <String>{'r'},
  );

  static const SyntaxGrammar _javascript = SyntaxGrammar(
    keywords: _jsKeywords,
    constants: <String>{'NaN', 'Infinity'},
    blockCommentStart: '/*',
    blockCommentEnd: '*/',
    stringDelimiters: <String>["'", '"', '`'],
  );

  static final SyntaxGrammar _typescript = SyntaxGrammar(
    keywords: <String>{
      ..._jsKeywords,
      'implements',
      'interface',
      'type',
      'enum',
      'declare',
      'namespace',
      'abstract',
      'private',
      'protected',
      'public',
      'readonly',
      'override',
    },
    types: _tsTypes,
    constants: <String>{'NaN', 'Infinity'},
    blockCommentStart: '/*',
    blockCommentEnd: '*/',
    stringDelimiters: <String>["'", '"', '`'],
  );

  static const SyntaxGrammar _python = SyntaxGrammar(
    keywords: _pythonKeywords,
    constants: <String>{'True', 'False', 'None'},
    lineComments: <String>['#'],
    tripleQuotedStrings: true,
  );

  static const SyntaxGrammar _json = SyntaxGrammar(
    keywords: <String>{},
    constants: <String>{'true', 'false', 'null'},
    lineComments: <String>[],
    stringDelimiters: <String>['"'],
    functionBeforeParen: false,
  );

  static const SyntaxGrammar _yaml = SyntaxGrammar(
    keywords: _yamlKeywords,
    lineComments: <String>['#'],
    constants: <String>{'true', 'false', 'null'},
  );

  static const SyntaxGrammar _html = SyntaxGrammar(
    keywords: <String>{'html', 'head', 'body', 'div', 'span', 'a', 'p', 'img', 'script', 'style', 'link', 'meta', 'title', 'section', 'main', 'header', 'footer'},
    blockCommentStart: '<!--',
    blockCommentEnd: '-->',
    stringDelimiters: <String>['"', "'"],
    functionBeforeParen: false,
  );

  static const SyntaxGrammar _css = SyntaxGrammar(
    keywords: <String>{'important', 'media', 'keyframes', 'import', 'font-face', 'supports', 'root', 'hover', 'focus', 'active', 'before', 'after'},
    blockCommentStart: '/*',
    blockCommentEnd: '*/',
    functionBeforeParen: false,
  );

  static const SyntaxGrammar _markdown = SyntaxGrammar(
    keywords: <String>{'true', 'false', 'null'},
    lineComments: <String>[],
    stringDelimiters: <String>['`'],
    functionBeforeParen: false,
  );

  static const SyntaxGrammar _shell = SyntaxGrammar(
    keywords: _shellKeywords,
    lineComments: <String>['#'],
    stringDelimiters: <String>["'", '"', '`'],
  );

  static const SyntaxGrammar _plain = SyntaxGrammar(
    lineComments: <String>[],
    functionBeforeParen: false,
  );

  static SyntaxGrammar of(EditorLanguage language) => switch (language) {
    EditorLanguage.dart => _dart,
    EditorLanguage.javascript => _javascript,
    EditorLanguage.typescript => _typescript,
    EditorLanguage.python => _python,
    EditorLanguage.json => _json,
    EditorLanguage.yaml => _yaml,
    EditorLanguage.html => _html,
    EditorLanguage.css => _css,
    EditorLanguage.markdown => _markdown,
    EditorLanguage.shell => _shell,
    EditorLanguage.plainText => _plain,
  };
}
