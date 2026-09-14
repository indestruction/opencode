import 'package:flutter/material.dart';
import 'package:opencode/domain/entities/code_token.dart';

abstract final class EditorSyntaxTheme {
  static const Color keyword = Color(0xFFC792EA);
  static const Color type = Color(0xFF82AAFF);
  static const Color constant = Color(0xFFFFCB6B);
  static const Color function = Color(0xFF82AAFF);
  static const Color string = Color(0xFFC3E88D);
  static const Color number = Color(0xFFF78C6C);
  static const Color comment = Color(0xFF5B6370);
  static const Color annotation = Color(0xFFFFCB6B);
  static const Color operator = Color(0xFF89DDFF);
  static const Color punctuation = Color(0xFF8A8F98);
  static const Color identifier = Color(0xFFECEFF4);
  static const Color plain = Color(0xFFECEFF4);

  static Color colorFor(CodeTokenType tokenType) => switch (tokenType) {
    CodeTokenType.keyword => keyword,
    CodeTokenType.type => type,
    CodeTokenType.constant => constant,
    CodeTokenType.function => function,
    CodeTokenType.string => string,
    CodeTokenType.number => number,
    CodeTokenType.comment => comment,
    CodeTokenType.annotation => annotation,
    CodeTokenType.operator => operator,
    CodeTokenType.punctuation => punctuation,
    CodeTokenType.identifier => identifier,
    CodeTokenType.plain => plain,
  };
}
