enum EditorLanguage {
  plainText('Plain Text', <String>[]),
  dart('Dart', <String>['dart']),
  javascript('JavaScript', <String>['js', 'mjs', 'cjs', 'jsx']),
  typescript('TypeScript', <String>['ts', 'tsx', 'mts', 'cts']),
  python('Python', <String>['py', 'pyw']),
  json('JSON', <String>['json', 'jsonc']),
  yaml('YAML', <String>['yaml', 'yml']),
  html('HTML', <String>['html', 'htm', 'xml', 'svg']),
  css('CSS', <String>['css', 'scss', 'less']),
  markdown('Markdown', <String>['md', 'markdown']),
  shell('Shell', <String>['sh', 'bash', 'zsh', 'fish']);

  const EditorLanguage(this.label, this.extensions);

  final String label;
  final List<String> extensions;

  static EditorLanguage fromPath(String path) {
    final int dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) {
      return EditorLanguage.plainText;
    }
    final String ext = path.substring(dot + 1).toLowerCase();
    for (final EditorLanguage language in EditorLanguage.values) {
      if (language.extensions.contains(ext)) {
        return language;
      }
    }
    return EditorLanguage.plainText;
  }
}
