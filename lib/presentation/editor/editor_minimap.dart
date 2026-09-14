import 'package:flutter/material.dart';
import 'package:opencode/core/theme/app_colors.dart';
import 'package:opencode/presentation/editor/editor_runtime.dart';

final class EditorMinimap extends StatelessWidget {
  const EditorMinimap({
    super.key,
    required this.runtime,
    required this.viewportHeight,
    required this.editorLineHeight,
    this.width = 54,
  });

  static const double _barSpacing = 3.6;

  final EditorRuntime runtime;
  final double viewportHeight;
  final double editorLineHeight;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: ListenableBuilder(
        listenable: runtime.controller,
        builder: (context, child) {
          final List<String> lines = runtime.controller.text.split('\n');
          return ValueListenableBuilder<double>(
            valueListenable: runtime.scrollOffset,
            builder: (context, offset, child) {
              final double factor = editorLineHeight <= 0
                  ? 0
                  : _barSpacing / editorLineHeight;
              final double indicatorTop = offset * factor;
              final double indicatorHeight =
                  (viewportHeight * factor).clamp(8.0, double.infinity).toDouble();
              return ClipRect(
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: -indicatorTop,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          for (final String line in lines)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 0.8,
                              ),
                              child: Container(
                                height: 1.8,
                                width: (line.length * 1.7)
                                    .clamp(4.0, width - 16)
                                    .toDouble(),
                                decoration: BoxDecoration(
                                  color: AppColors.textFaded.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: indicatorTop,
                      left: 0,
                      right: 0,
                      height: indicatorHeight,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
