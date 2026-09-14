final class DemoFile {
  const DemoFile({
    required this.name,
    required this.path,
    required this.language,
    required this.content,
  });

  final String name;
  final String path;
  final String language;
  final String content;
}

const List<DemoFile> kDemoFiles = <DemoFile>[
  DemoFile(
    name: 'main.dart',
    path: 'lib/main.dart',
    language: 'dart',
    content: '''import 'package:flutter/material.dart';

void main() {
  runApp(const OpencodeApp());
}

class OpencodeApp extends StatelessWidget {
  const OpencodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opencode',
      theme: ThemeData(brightness: Brightness.dark),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Hello, Opencode')),
    );
  }
}''',
  ),
  DemoFile(
    name: 'home_screen.dart',
    path: 'lib/presentation/screens/home_screen.dart',
    language: 'dart',
    content: '''import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    if (size.width > 900) {
      return const WideLayout();
    }
    return const CompactLayout();
  }
}''',
  ),
  DemoFile(
    name: 'ai_provider.dart',
    path: 'lib/domain/ai/base_ai_provider.dart',
    language: 'dart',
    content: '''abstract class BaseAiProvider {
  const BaseAiProvider(this.config);

  final AiProviderConfig config;

  Stream<AiStreamEvent> streamChat(AiCompletionRequest request);

  Future<List<String>> listModels();

  Future<bool> healthCheck();
}''',
  ),
  DemoFile(
    name: 'pubspec.yaml',
    path: 'pubspec.yaml',
    language: 'yaml',
    content: '''name: opencode
description: Mobile code editor and AI agent.
publish_to: "none"
version: 0.1.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  http: ^1.2.2
  flutter_secure_storage: ^9.2.2
''',
  ),
];
