import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencode/data/editor/editor_highlight_service.dart';
import 'package:opencode/presentation/editor/editor_runtime.dart';

final Provider<EditorRuntimeStore> editorRuntimeStoreProvider =
    Provider<EditorRuntimeStore>((ref) {
      final EditorRuntimeStore store = EditorRuntimeStore();
      ref.onDispose(store.disposeAll);
      return store;
    });

final Provider<EditorCommandBus> editorCommandBusProvider =
    Provider<EditorCommandBus>((ref) {
      final EditorCommandBus bus = EditorCommandBus();
      ref.onDispose(bus.dispose);
      return bus;
    });

final Provider<EditorHighlightService> editorHighlightServiceProvider =
    Provider<EditorHighlightService>((ref) => EditorHighlightService());
