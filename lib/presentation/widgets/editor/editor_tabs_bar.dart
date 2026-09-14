import 'package:flutter/material.dart';
import 'package:opencode/core/theme/app_colors.dart';
import 'package:opencode/core/theme/app_typography.dart';
import 'package:opencode/presentation/providers/editor_tabs_controller.dart';

final class EditorTabsBar extends StatelessWidget {
  const EditorTabsBar({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onClose,
  });

  final EditorTabsState state;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.tabs.length,
        itemBuilder: (context, index) {
          final EditorTab tab = state.tabs[index];
          return _Tab(
            label: tab.name,
            dirty: tab.dirty,
            active: index == state.activeIndex,
            onTap: () => onSelect(index),
            onClose: () => onClose(index),
          );
        },
      ),
    );
  }
}

final class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.dirty,
    required this.onTap,
    required this.onClose,
  });

  final String label;
  final bool active;
  final bool dirty;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.tabActive : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: active ? AppColors.neonCyan : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            Text(
              label,
              style: AppTypography.code(
                fontSize: 12,
                color: active
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            if (dirty) ...<Widget>[
              const SizedBox(width: 6),
              const _DirtyDot(),
            ],
            const SizedBox(width: 4),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.close,
                  size: 13,
                  color: AppColors.textFaded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DirtyDot extends StatelessWidget {
  const _DirtyDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 6,
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.neonCyan,
        ),
      ),
    );
  }
}
