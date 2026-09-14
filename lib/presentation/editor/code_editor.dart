import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencode/core/theme/app_colors.dart';
import 'package:opencode/core/theme/app_typography.dart';
import 'package:opencode/domain/entities/code_token.dart';
import 'package:opencode/presentation/editor/editor_runtime.dart';
import 'package:opencode/presentation/editor/line_layout.dart';
import 'package:opencode/presentation/providers/editor_runtime_providers.dart';
import 'package:opencode/presentation/providers/editor_tabs_controller.dart';

final class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({super.key, required this.tab});

  final EditorTab tab;

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

final class _CodeEditorState extends ConsumerState<CodeEditor> {
  static const double gutterWidth = 54;
  static const double contentPadding = 10;
  static const Duration _highlightDebounce = Duration(milliseconds: 140);

  late final EditorRuntime _runtime;
  Timer? _highlightTimer;
  TextSelection? _lastSelection;
  int _activeLine = 0;
  String _layoutText = '';
  double _layoutWidth = -1;
  EditorLineLayout _layout = const EditorLineLayout(
    lineHeight: 20,
    totalHeight: 20,
    logicalTops: <double>[0],
    logicalHeights: <double>[20],
  );

  TextStyle get _codeStyle => AppTypography.code(fontSize: 13.5, height: 1.5);

  @override
  void initState() {
    super.initState();
    _runtime = ref.read(editorRuntimeStoreProvider).runtimeFor(widget.tab);
    _runtime.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(editorCommandBusProvider).attach(_runtime);
      unawaited(_highlight());
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _runtime.controller.removeListener(_onControllerChanged);
    ref.read(editorCommandBusProvider).detach(_runtime);
    super.dispose();
  }

  void _onControllerChanged() {
    final TextSelection selection = _runtime.controller.selection;
    if (selection == _lastSelection) {
      return;
    }
    _lastSelection = selection;
    final int line = _lineOfOffset(
      _runtime.controller.text,
      selection.baseOffset,
    );
    if (line != _activeLine && mounted) {
      setState(() => _activeLine = line);
    }
  }

  void _handleTextChanged(String value) {
    ref
        .read(editorTabsControllerProvider.notifier)
        .updateContent(widget.tab.path, value);
    final int line = _lineOfOffset(
      value,
      _runtime.controller.selection.baseOffset,
    );
    setState(() => _activeLine = line);
    _scheduleHighlight();
  }

  int _lineOfOffset(String text, int offset) {
    if (offset < 0) {
      return 0;
    }
    final int limit = offset.clamp(0, text.length).toInt();
    int line = 0;
    for (int i = 0; i < limit; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        line++;
      }
    }
    return line;
  }

  void _scheduleHighlight() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightDebounce, () {
      unawaited(_highlight());
    });
  }

  Future<void> _highlight() async {
    final String source = _runtime.controller.text;
    final List<CodeToken> tokens = await ref
        .read(editorHighlightServiceProvider)
        .highlight(source: source, language: _runtime.language);
    if (!mounted || source != _runtime.controller.text) {
      return;
    }
    _runtime.tokens = tokens;
    _runtime.controller.tokens = tokens;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle codeStyle = _codeStyle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double textWidth =
            constraints.maxWidth - gutterWidth - contentPadding * 2;
        final String text = _runtime.controller.text;
        if (textWidth != _layoutWidth || text != _layoutText) {
          _layoutWidth = textWidth;
          _layoutText = text;
          _layout = EditorLineLayoutBuilder.build(
            text: text,
            style: codeStyle,
            maxWidth: textWidth,
          );
        }

        return ColoredBox(
          color: AppColors.background,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Gutter(
                layout: _layout,
                activeLine: _activeLine,
                scrollOffset: _runtime.scrollOffset,
                width: gutterWidth,
                topPadding: contentPadding,
              ),
              Expanded(child: _buildTextArea(codeStyle)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextArea(TextStyle codeStyle) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ValueListenableBuilder<double>(
          valueListenable: _runtime.scrollOffset,
          builder: (context, offset, child) {
            final double top =
                contentPadding + _layout.topOf(_activeLine) - offset;
            return Transform.translate(
              offset: Offset(0, top),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: _layout.heightOf(_activeLine),
                  width: double.infinity,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.activeLine,
                      border: Border(
                        left: BorderSide(color: AppColors.neonCyan, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final double pixels = notification.metrics.pixels;
            if (pixels != _runtime.scrollOffset.value) {
              _runtime.scrollOffset.value = pixels;
            }
            return false;
          },
          child: TextField(
            controller: _runtime.controller,
            focusNode: _runtime.focusNode,
            scrollController: _runtime.verticalScroll,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            style: codeStyle,
            strutStyle: StrutStyle.fromTextStyle(
              codeStyle,
              forceStrutHeight: true,
            ),
            cursorColor: AppColors.neonCyan,
            cursorWidth: 2,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: _handleTextChanged,
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: contentPadding,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _Gutter extends StatelessWidget {
  const _Gutter({
    required this.layout,
    required this.activeLine,
    required this.scrollOffset,
    required this.width,
    required this.topPadding,
  });

  final EditorLineLayout layout;
  final int activeLine;
  final ValueListenable<double> scrollOffset;
  final double width;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppTypography.code(
      fontSize: 11.5,
      color: AppColors.textFaded,
      height: 1.5,
    );

    return SizedBox(
      width: width,
      child: ClipRect(
        child: ValueListenableBuilder<double>(
          valueListenable: scrollOffset,
          builder: (context, offset, child) {
            return Transform.translate(
              offset: Offset(0, topPadding - offset),
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minHeight: 0,
                maxHeight: double.infinity,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < layout.logicalHeights.length; i++)
                SizedBox(
                  height: layout.logicalHeights[i],
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, top: 1),
                      child: Text(
                        '${i + 1}',
                        style: i == activeLine
                            ? base.copyWith(color: AppColors.neonCyan)
                            : base,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
