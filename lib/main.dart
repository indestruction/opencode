import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencode/app.dart';
import 'package:opencode/data/ai/ai_provider_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AiProviderBootstrap.ensureRegistered();
  runApp(const ProviderScope(child: OpencodeApp()));
}
