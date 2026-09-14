import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencode/core/theme/app_colors.dart';
import 'package:opencode/core/theme/app_typography.dart';
import 'package:opencode/presentation/data/demo_project.dart';
import 'package:opencode/presentation/providers/editor_tabs_controller.dart';

final class FileExplorerDrawer extends ConsumerWidget {
  const FileExplorerDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EditorTabsState tabsState = ref.watch(editorTabsControllerProvider);
    final String? activePath = tabsState.active?.path;

    void openFile(DemoFile file) {
      ref
          .read(editorTabsControllerProvider.notifier)
          .open(EditorTab.fromDemoFile(file));
      Navigator.of(context).maybePop();
    }

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Color(0xF716161C),
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _DrawerHeader(),
            const Divider(height: 1, color: AppColors.borderSubtle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: <Widget>[
                  const _SectionLabel('EXPLORER'),
                  const _FolderTile(label: 'lib'),
                  for (final DemoFile file in kDemoFiles)
                    if (file.path.startsWith('lib/'))
                      _FileTile(
                        file: file,
                        selected: activePath == file.path,
                        onTap: () => openFile(file),
                      ),
                  for (final DemoFile file in kDemoFiles)
                    if (!file.path.startsWith('lib/'))
                      _FileTile(
                        file: file,
                        selected: activePath == file.path,
                        onTap: () => openFile(file),
                      ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const _GitFooter(),
          ],
        ),
      ),
    );
  }
}

final class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Row(
        children: <Widget>[
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: <Color>[AppColors.neonCyan, AppColors.neonViolet],
            ).createShader(bounds),
            child: const Text(
              'opencode',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'v0.1.0',
            style: TextStyle(fontSize: 10.5, color: AppColors.textFaded),
          ),
        ],
      ),
    );
  }
}

final class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textFaded,
        ),
      ),
    );
  }
}

final class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: <Widget>[
          const Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Icon(Icons.folder_outlined, size: 15, color: AppColors.neonViolet),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

final class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.selected,
    required this.onTap,
  });

  final DemoFile file;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (file.language) {
    'dart' => Icons.flutter_dash,
    'yaml' => Icons.tune,
    _ => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(34, 8, 16, 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.activeLine : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? AppColors.neonCyan : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              _icon,
              size: 14,
              color: selected ? AppColors.neonCyan : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file.name,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.code(
                  fontSize: 12.5,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _GitFooter extends StatelessWidget {
  const _GitFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: <Widget>[
          Icon(Icons.call_split, size: 15, color: AppColors.neonGreen),
          SizedBox(width: 8),
          Text(
            'main',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Spacer(),
          Text(
            'Git · soon',
            style: TextStyle(fontSize: 10.5, color: AppColors.textFaded),
          ),
        ],
      ),
    );
  }
}
