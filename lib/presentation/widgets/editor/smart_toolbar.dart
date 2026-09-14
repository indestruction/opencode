import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencode/core/theme/app_colors.dart';
import 'package:opencode/core/theme/app_typography.dart';
import 'package:opencode/presentation/widgets/common/glass_panel.dart';

final class SmartToolbar extends StatelessWidget {
  const SmartToolbar({super.key, required this.onInsert});

  final ValueChanged<String> onInsert;

  static const List<String> _keys = <String>[
    'Tab',
    '{',
    '}',
    '(',
    ')',
    '[',
    ']',
    '<',
    '>',
    ';',
    ':',
    ',',
    '.',
    '=>',
    '==',
    '!=',
    '&&',
    '||',
    '->',
    '+',
    '-',
    '*',
    '/',
    '%',
    '=',
    '!',
    '#',
    r'$',
    "'",
    '"',
    '`',
    '_',
    '&',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: GlassPanel(
        borderRadius: 14,
        color: AppColors.glassStrong,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _keys.length,
            separatorBuilder: (context, index) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final String key = _keys[index];
              return _SmartKey(
                label: key,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onInsert(key);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _SmartKey extends StatelessWidget {
  const _SmartKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 36),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Text(
            label,
            style: AppTypography.code(fontSize: 12.5),
          ),
        ),
      ),
    );
  }
}
