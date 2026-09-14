import 'package:flutter/material.dart';

final class NeonDot extends StatelessWidget {
  const NeonDot({
    super.key,
    required this.color,
    this.size = 7,
    this.pulsing = false,
  });

  final Color color;
  final double size;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    if (!pulsing) {
      return _Dot(color: color, size: size);
    }
    return _PulsingDot(color: color, size: size);
  }
}

final class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 8),
        ],
      ),
    );
  }
}

final class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

final class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_opacity),
      child: _Dot(color: widget.color, size: widget.size),
    );
  }
}
