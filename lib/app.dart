import 'package:flutter/material.dart';
import 'package:opencode/core/theme/app_theme.dart';
import 'package:opencode/presentation/screens/home/home_screen.dart';

final class OpencodeApp extends StatelessWidget {
  const OpencodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opencode',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
