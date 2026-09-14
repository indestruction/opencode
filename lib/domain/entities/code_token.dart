enum CodeTokenType {
  keyword,
  type,
  constant,
  function,
  string,
  number,
  comment,
  annotation,
  operator,
  punctuation,
  identifier,
  plain,
}

final class CodeToken {
  const CodeToken({
    required this.start,
    required this.end,
    required this.type,
  });

  final int start;
  final int end;
  final CodeTokenType type;

  int get length => end - start;
}
