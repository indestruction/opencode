import 'package:flutter/material.dart';

final class EditorLineLayout {
  const EditorLineLayout({
    required this.lineHeight,
    required this.totalHeight,
    required this.logicalTops,
    required this.logicalHeights,
  });

  final double lineHeight;
  final double totalHeight;
  final List<double> logicalTops;
  final List<double> logicalHeights;

  int get lineCount => logicalTops.length;

  double topOf(int index) =>
      index >= 0 && index < logicalTops.length ? logicalTops[index] : 0;

  double heightOf(int index) => index >= 0 && index < logicalHeights.length
      ? logicalHeights[index]
      : lineHeight;

  int lineAtOffset(double y) {
    for (int i = logicalTops.length - 1; i >= 0; i--) {
      if (y >= logicalTops[i]) {
        return i;
      }
    }
    return 0;
  }
}

abstract final class EditorLineLayoutBuilder {
  static EditorLineLayout build({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final double fallbackHeight =
        (style.fontSize ?? 14) * (style.height ?? 1.2);
    final int logicalLineCount = '\n'.allMatches(text).length + 1;

    if (text.isEmpty) {
      return EditorLineLayout(
        lineHeight: fallbackHeight,
        totalHeight: fallbackHeight,
        logicalTops: const <double>[0],
        logicalHeights: <double>[fallbackHeight],
      );
    }

    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
    )..layout(maxWidth: maxWidth <= 0 ? double.infinity : maxWidth);

    final List<LineMetrics> metrics = painter.computeLineMetrics();
    double lineHeight = metrics.isNotEmpty ? metrics.first.height : fallbackHeight;

    final List<double> tops = <double>[];
    final List<double> heights = <double>[];
    double y = 0;
    double currentTop = 0;
    double currentHeight = 0;

    for (final LineMetrics metric in metrics) {
      if (currentHeight == 0) {
        currentTop = y;
      }
      currentHeight += metric.height;
      y += metric.height;
      if (metric.hardBreak) {
        tops.add(currentTop);
        heights.add(currentHeight);
        currentHeight = 0;
      }
    }

    if (currentHeight > 0) {
      tops.add(currentTop);
      heights.add(currentHeight);
    } else {
      tops.add(y);
      heights.add(lineHeight);
      y += lineHeight;
    }

    while (tops.length < logicalLineCount) {
      tops.add(y);
      heights.add(lineHeight);
      y += lineHeight;
    }

    painter.dispose();

    return EditorLineLayout(
      lineHeight: lineHeight,
      totalHeight: y,
      logicalTops: tops,
      logicalHeights: heights,
    );
  }
}
