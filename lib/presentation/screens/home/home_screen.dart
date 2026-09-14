import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencode/core/theme/app_colors.dart';
import 'package:opencode/core/theme/app_typography.dart';
import 'package:opencode/di/injector.dart';
import 'package:opencode/domain/ai/base_ai_provider.dart';
import 'package:opencode/presentation/editor/code_editor.dart';
import 'package:opencode/presentation/editor/editor_minimap.dart';
import 'package:opencode/presentation/editor/editor_runtime.dart';
import 'package:opencode/presentation/providers/editor_runtime_providers.dart';
import 'package:opencode/presentation/providers/editor_tabs_controller.dart';
import 'package:opencode/presentation/widgets/ai/ai_chat_panel.dart';
import 'package:opencode/presentation/widgets/common/neon_dot.dart';
import 'package:opencode/presentation/widgets/editor/editor_tabs_bar.dart';
import 'package:opencode/presentation/widgets/editor/smart_toolbar.dart';
import 'package:opencode/presentation/widgets/explorer/file_explorer_drawer.dart';

final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const double _editorLineHeight = 13.5 * 1.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const FileExplorerDrawer(),
      endDrawer: const AiChatPanel(),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final EditorTabsState tabsState = ref.watch(
              editorTabsControllerProvider,
            );
            final EditorTab? activeTab = tabsState.active;
            final AsyncValue<BaseAiProvider> aiStatus = ref.watch(
              activeAiProviderProvider,
            );
            final EditorRuntimeStore runtimeStore = ref.watch(
              editorRuntimeStoreProvider,
            );
            final EditorRuntime? runtime = activeTab == null
                ? null
                : runtimeStore.runtimeFor(activeTab);

            return Column(
              children: <Widget>[
                _Header(
                  fileName: activeTab?.name,
                  dirty: activeTab?.dirty ?? false,
                  aiStatus: aiStatus,
                  onMenu: () => Scaffold.of(context).openDrawer(),
                  onOpenAi: () => Scaffold.of(context).openEndDrawer(),
                ),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            EditorTabsBar(
                              state: tabsState,
                              onSelect: (index) => ref
                                  .read(editorTabsControllerProvider.notifier)
                                  .select(index),
                              onClose: (index) {
                                final EditorTab closed = tabsState.tabs[index];
                                final EditorRuntimeStore store = ref.read(
                                  editorRuntimeStoreProvider,
                                );
                                ref
                                    .read(editorTabsControllerProvider.notifier)
                                    .close(index);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  store.close(closed.path);
                                });
                              },
                            ),
                            Expanded(
                              child: activeTab == null || runtime == null
                                  ? const _EmptyWorkspace()
                                  : CodeEditor(
                                      key: ValueKey<String>(activeTab.path),
                                      tab: activeTab,
                                    ),
                            ),
                            SmartToolbar(
                              onInsert: (token) => ref
                                  .read(editorCommandBusProvider)
                                  .smartInsert(token),
                            ),
                          ],
                        ),
                      ),
                      if (runtime == null)
                        const SizedBox(width: 54)
                      else
                        LayoutBuilder(
                          builder: (context, constraints) => SizedBox(
                            height: constraints.maxHeight,
                            child: EditorMinimap(
                              runtime: runtime,
                              viewportHeight: constraints.maxHeight,
                              editorLineHeight: _editorLineHeight,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.code_rounded, size: 44, color: AppColors.textFaded),
            SizedBox(height: 12),
            Text(
              'No file open',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Open a file from the explorer',
              style: TextStyle(color: AppColors.textFaded, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({
    required this.fileName,
    required this.dirty,
    required this.aiStatus,
    required this.onMenu,
    required this.onOpenAi,
  });

  final String? fileName;
  final bool dirty;
  final AsyncValue<BaseAiProvider> aiStatus;
  final VoidCallback onMenu;
  final VoidCallback onOpenAi;

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (aiStatus) {
      AsyncData<BaseAiProvider>(:final BaseAiProvider value) => (
        AppColors.neonGreen,
        value.config.displayName,
      ),
      AsyncError<BaseAiProvider>() => (AppColors.danger, 'offline'),
      _ => (AppColors.textFaded, 'connecting'),
    };

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0xF0121215),
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Explorer',
            onPressed: onMenu,
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      fileName ?? 'opencode',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.code(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (dirty) ...<Widget>[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _AiStatusPill(color: color, label: label, onTap: onOpenAi),
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_outlined,
              color: AppColors.neonViolet,
            ),
            tooltip: 'AI Agent',
            onPressed: onOpenAi,
          ),
        ],
      ),
    );
  }
}

final class _AiStatusPill extends StatelessWidget {
  const _AiStatusPill({
    required this.color,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeonDot(color: color, size: 6),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
