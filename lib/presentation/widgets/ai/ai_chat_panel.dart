import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencode/core/theme/app_colors.dart';
import 'package:opencode/core/theme/app_typography.dart';
import 'package:opencode/di/injector.dart';
import 'package:opencode/domain/ai/base_ai_provider.dart';
import 'package:opencode/domain/entities/ai_message.dart';
import 'package:opencode/domain/entities/ai_provider_config.dart';
import 'package:opencode/presentation/providers/ai_chat_controller.dart';
import 'package:opencode/presentation/widgets/common/glass_panel.dart';
import 'package:opencode/presentation/widgets/common/neon_dot.dart';

final class AiChatPanel extends ConsumerStatefulWidget {
  const AiChatPanel({super.key});

  @override
  ConsumerState<AiChatPanel> createState() => _AiChatPanelState();
}

final class _AiChatPanelState extends ConsumerState<AiChatPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _inputController.text;
    if (text.trim().isEmpty) {
      return;
    }
    _inputController.clear();
    ref.read(aiChatControllerProvider.notifier).send(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiChatState>(aiChatControllerProvider, (previous, next) {
      final bool grew =
          next.entries.length > (previous?.entries.length ?? 0);
      final bool streamed =
          previous != null &&
          previous.entries.isNotEmpty &&
          next.entries.isNotEmpty &&
          previous.entries.last.message.content !=
              next.entries.last.message.content;
      if (grew || streamed) {
        _scrollToBottom();
      }
    });

    final AiChatState chat = ref.watch(aiChatControllerProvider);
    final List<AiProviderConfig> configs = ref.watch(aiProviderConfigsProvider);
    final AiProviderConfig activeConfig = ref.watch(
      activeAiProviderConfigProvider,
    );
    final AsyncValue<BaseAiProvider> providerState = ref.watch(
      activeAiProviderProvider,
    );
    final double width = (MediaQuery.sizeOf(context).width * 0.92)
        .clamp(280.0, 400.0)
        .toDouble();

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xF7121215),
        border: Border(left: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _ChatHeader(
              configs: configs,
              activeConfig: activeConfig,
              providerState: providerState,
              isBusy: chat.isBusy,
              onSelectProvider: (id) =>
                  ref.read(activeAiProviderIdProvider.notifier).state = id,
              onClear: () =>
                  ref.read(aiChatControllerProvider.notifier).clear(),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
            Expanded(
              child: chat.entries.isEmpty
                  ? const _EmptyChat()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: chat.entries.length,
                      itemBuilder: (context, index) =>
                          _ChatBubble(entry: chat.entries[index]),
                    ),
            ),
            if (chat.error != null) _ErrorBanner(message: chat.error!),
            _ChatInput(
              controller: _inputController,
              isBusy: chat.isBusy,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.configs,
    required this.activeConfig,
    required this.providerState,
    required this.isBusy,
    required this.onSelectProvider,
    required this.onClear,
  });

  final List<AiProviderConfig> configs;
  final AiProviderConfig activeConfig;
  final AsyncValue<BaseAiProvider> providerState;
  final bool isBusy;
  final ValueChanged<String> onSelectProvider;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final (Color statusColor, String statusLabel) = switch (providerState) {
      AsyncData<BaseAiProvider>() => (AppColors.neonGreen, activeConfig.displayName),
      AsyncError<BaseAiProvider>() => (AppColors.danger, 'unavailable'),
      _ => (AppColors.textFaded, 'connecting…'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: <Widget>[
          NeonDot(color: statusColor, pulsing: isBusy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'AI Agent',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$statusLabel · ${activeConfig.defaultModel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textFaded,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, size: 18),
            tooltip: 'Switch provider',
            onSelected: onSelectProvider,
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              for (final AiProviderConfig config in configs)
                PopupMenuItem<String>(
                  value: config.id,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        config.id == activeConfig.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 15,
                        color: config.id == activeConfig.id
                            ? AppColors.neonCyan
                            : AppColors.textFaded,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(config.displayName)),
                      if (config.isLocal)
                        const Text(
                          'local',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.neonGreen,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            tooltip: 'Clear chat',
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

final class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.auto_awesome, size: 34, color: AppColors.neonViolet),
            SizedBox(height: 14),
            Text(
              'Ask about your code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Open files are attached as context automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textFaded),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.entry});

  final ChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final bool isUser = entry.message.role == AiMessageRole.user;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 32),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[AppColors.neonCyan, AppColors.neonViolet],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: Text(
            entry.message.content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF0B0B0F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 24),
        child: GlassPanel(
          borderRadius: 14,
          color: AppColors.glassStrong,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: entry.streaming && entry.message.content.isEmpty
              ? const _TypingDots()
              : Text(
                  entry.message.content,
                  style: AppTypography.code(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

final class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

final class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: _dotOpacity(i),
                  child: const SizedBox(
                    width: 6,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonCyan,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _dotOpacity(int index) {
    final double phase = (_controller.value + index * 0.2) % 1.0;
    final double wave = (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0).toDouble();
    return 0.25 + 0.75 * wave;
  }
}

final class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: GlassPanel(
        borderRadius: 10,
        color: AppColors.danger.withOpacity(0.12),
        borderColor: AppColors.danger.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            const Icon(Icons.warning_amber, size: 16, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isBusy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isBusy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: GlassPanel(
        borderRadius: 16,
        color: AppColors.glassStrong,
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask AI about your code…',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final bool enabled = value.text.trim().isNotEmpty && !isBusy;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: InkWell(
                    onTap: enabled ? onSend : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: enabled
                            ? const LinearGradient(
                                colors: <Color>[
                                  AppColors.neonCyan,
                                  AppColors.neonViolet,
                                ],
                              )
                            : null,
                        color: enabled ? null : AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isBusy ? Icons.hourglass_top : Icons.arrow_upward,
                        size: 17,
                        color: enabled
                            ? const Color(0xFF0B0B0F)
                            : AppColors.textFaded,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
