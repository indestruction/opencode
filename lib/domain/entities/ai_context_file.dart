final class AiContextFile {
  const AiContextFile({
    required this.path,
    required this.language,
    required this.content,
  });

  final String path;
  final String language;
  final String content;

  String toPromptBlock() =>
      '--- file: $path ($language) ---\n$content\n--- end of $path ---';
}
