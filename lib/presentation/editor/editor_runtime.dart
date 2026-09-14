import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencode/domain/entities/code_token.dart';
import 'package:opencode/domain/entities/editor_language.dart';
import 'package:opencode/presentation/editor/code_editing_controller.dart';
import 'package:opencode/presentation/providers/editor_tabs_controller.dart';

final class EditorRuntime {
  EditorRuntime._({
    required this.language,
    required this.controller,
    required this.verticalScroll,
    required this.focusNode,
    required this.scrollOffset,
  });

  factory EditorRuntime(EditorTab tab) {
    final EditorLanguage language = EditorLanguage.fromPath(tab.path);
    return EditorRuntime._(
      language: language,
      controller: CodeEditingController(text: tab.content, language: language),
      verticalScroll: ScrollController(),
      focusNode: FocusNode(),
      scrollOffset: ValueNotifier<double>(0),
    );
  }

  final CodeEditingController controller;
  final ScrollController verticalScroll;
  final FocusNode focusNode;
  final ValueNotifier<double> scrollOffset;
  EditorLanguage language;
  List<CodeToken> tokens = const <CodeToken>[];

  void dispose() {
    controller.dispose();
    verticalScroll.dispose();
    focusNode.dispose();
    scrollOffset.dispose();
  }
}

final class EditorRuntimeStore {
  final Map<String, EditorRuntime> _runtimes = <String, EditorRuntime>{};

  EditorRuntime runtimeFor(EditorTab tab) =>
      _runtimes.putIfAbsent(tab.path, () => EditorRuntime(tab));

  EditorRuntime? runtimeOf(String path) => _runtimes[path];

  void close(String path) => _runtimes.remove(path)?.dispose();

  void disposeAll() {
    for (final EditorRuntime runtime in _runtimes.values) {
      runtime.dispose();
    }
    _runtimes.clear();
  }
}

final class EditorCommandBus extends ChangeNotifier {
  static const Map<String, String> _pairs = <String, String>{
    '{': '}',
    '(': ')',
    '[': ']',
    '<': '>',
    '"': '"',
    "'": "'",
    '`': '`',
  };

  EditorRuntime? _runtime;

  EditorRuntime? get runtime => _runtime;

  CodeEditingController? get controller => _runtime?.controller;

  bool get isAttached => _runtime != null;

  void attach(EditorRuntime runtime) {
    _runtime = runtime;
    notifyListeners();
  }

  void detach(EditorRuntime runtime) {
    if (identical(_runtime, runtime)) {
      _runtime = null;
      notifyListeners();
    }
  }

  void smartInsert(String token) {
    if (token == 'Tab') {
      insert('  ');
      return;
    }
    final String? closing = _pairs[token];
    if (closing != null) {
      _insertPair(token, closing);
      return;
    }
    insert(token);
  }

  void insert(String text) {
    final CodeEditingController? controller = this.controller;
    if (controller == null) {
      return;
    }
    final TextEditingValue value = controller.value;
    final TextSelection selection = value.selection;
    if (selection.isValid) {
      final String newText =
          value.text.replaceRange(selection.start, selection.end, text);
      controller.value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
        composing: TextRange.empty,
      );
    } else {
      final String newText = value.text + text;
      controller.value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    }
  }

  void replaceSelection(String text) {
    final CodeEditingController? controller = this.controller;
    if (controller == null) {
      return;
    }
    final TextEditingValue value = controller.value;
    final TextSelection selection = value.selection;
    final int start = selection.isValid ? selection.start : value.text.length;
    final int end = selection.isValid ? selection.end : value.text.length;
    final String newText = value.text.replaceRange(start, end, text);
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
      composing: TextRange.empty,
    );
  }

  void newlineWithIndent() {
    final CodeEditingController? controller = this.controller;
    if (controller == null) {
      return;
    }
    final TextEditingValue value = controller.value;
    final TextSelection selection = value.selection;
    final int offset = selection.isValid ? selection.start : value.text.length;
    final int searchFrom = offset > 0 ? offset - 1 : 0;
    final int lineStart = value.text.lastIndexOf('\n', searchFrom) + 1;
    final String line = value.text.substring(lineStart, offset);
    final String indent = _leadingWhitespace(line);
    final String trimmed = line.trimRight();
    final bool opensBlock = trimmed.endsWith('{') ||
        trimmed.endsWith('(') ||
        trimmed.endsWith('[') ||
        trimmed.endsWith(':');
    final String inserted = '\n$indent${opensBlock ? '  ' : ''}';
    final String newText = value.text.replaceRange(offset, offset, inserted);
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + inserted.length),
      composing: TextRange.empty,
    );
  }

  void _insertPair(String opening, String closing) {
    final CodeEditingController? controller = this.controller;
    if (controller == null) {
      return;
    }
    final TextEditingValue value = controller.value;
    final TextSelection selection = value.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final String selected = value.text.substring(selection.start, selection.end);
      final String newText = value.text.replaceRange(
        selection.start,
        selection.end,
        '$opening$selected$closing',
      );
      controller.value = value.copyWith(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + opening.length,
          extentOffset: selection.start + opening.length + selected.length,
        ),
        composing: TextRange.empty,
      );
      return;
    }
    final int offset = selection.isValid ? selection.start : value.text.length;
    final String newText = value.text.replaceRange(offset, offset, '$opening$closing');
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + opening.length),
      composing: TextRange.empty,
    );
  }

  String _leadingWhitespace(String line) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final String ch = line[i];
      if (ch == ' ' || ch == '\t') {
        buffer.write(ch);
      } else {
        break;
      }
    }
    return buffer.toString();
  }
}
