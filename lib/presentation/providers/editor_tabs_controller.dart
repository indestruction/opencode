import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencode/presentation/data/demo_project.dart';

final class EditorTab {
  const EditorTab({
    required this.name,
    required this.path,
    required this.language,
    required this.content,
    this.dirty = false,
  });

  factory EditorTab.fromDemoFile(DemoFile file) => EditorTab(
    name: file.name,
    path: file.path,
    language: file.language,
    content: file.content,
  );

  final String name;
  final String path;
  final String language;
  final String content;
  final bool dirty;

  EditorTab copyWith({String? content, bool? dirty}) => EditorTab(
    name: name,
    path: path,
    language: language,
    content: content ?? this.content,
    dirty: dirty ?? this.dirty,
  );
}

final class EditorTabsState {
  const EditorTabsState({required this.tabs, this.activeIndex = 0});

  final List<EditorTab> tabs;
  final int activeIndex;

  EditorTab? get active => tabs.isEmpty
      ? null
      : tabs[activeIndex.clamp(0, tabs.length - 1).toInt()];

  EditorTabsState copyWith({List<EditorTab>? tabs, int? activeIndex}) =>
      EditorTabsState(
        tabs: tabs ?? this.tabs,
        activeIndex: activeIndex ?? this.activeIndex,
      );
}

final class EditorTabsController extends Notifier<EditorTabsState> {
  @override
  EditorTabsState build() {
    final List<EditorTab> initial = <EditorTab>[
      for (final DemoFile file in kDemoFiles.take(2))
        EditorTab.fromDemoFile(file),
    ];
    return EditorTabsState(tabs: initial);
  }

  void select(int index) {
    if (index < 0 || index >= state.tabs.length) {
      return;
    }
    state = state.copyWith(activeIndex: index);
  }

  void open(EditorTab tab) {
    final int existingIndex = state.tabs.indexWhere(
      (candidate) => candidate.path == tab.path,
    );
    if (existingIndex >= 0) {
      select(existingIndex);
      return;
    }
    state = state.copyWith(
      tabs: <EditorTab>[...state.tabs, tab],
      activeIndex: state.tabs.length,
    );
  }

  void close(int index) {
    if (index < 0 || index >= state.tabs.length) {
      return;
    }

    final List<EditorTab> tabs = <EditorTab>[...state.tabs]..removeAt(index);
    int active = state.activeIndex;
    if (index < active) {
      active -= 1;
    } else if (active >= tabs.length) {
      active = tabs.isEmpty ? 0 : tabs.length - 1;
    }
    state = EditorTabsState(tabs: tabs, activeIndex: active);
  }

  void updateContent(String path, String content) {
    final int index = state.tabs.indexWhere((tab) => tab.path == path);
    if (index < 0) {
      return;
    }
    final EditorTab tab = state.tabs[index];
    if (tab.content == content && tab.dirty) {
      return;
    }
    final List<EditorTab> tabs = <EditorTab>[...state.tabs];
    tabs[index] = tab.copyWith(content: content, dirty: true);
    state = state.copyWith(tabs: tabs);
  }
}

final NotifierProvider<EditorTabsController, EditorTabsState>
editorTabsControllerProvider =
    NotifierProvider<EditorTabsController, EditorTabsState>(
      EditorTabsController.new,
    );
