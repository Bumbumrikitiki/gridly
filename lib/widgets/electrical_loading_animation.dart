import 'dart:math' as math;

import 'package:flutter/material.dart';

class ShimmerText extends StatefulWidget {
  const ShimmerText({
    required this.text,
    required this.style,
    this.shimmerColor = Colors.white,
    super.key,
  });

  final String text;
  final TextStyle style;
  final Color shimmerColor;

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final width = bounds.width <= 0 ? 1.0 : bounds.width;
            final slide = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.2 + (2.4 * slide), 0),
              end: Alignment(-0.2 + (2.4 * slide), 0),
              colors: [
                widget.style.color ?? Colors.white70,
                widget.shimmerColor,
                widget.style.color ?? Colors.white70,
              ],
              stops: const [0.1, 0.5, 0.9],
            ).createShader(Rect.fromLTWH(0, 0, width, bounds.height));
          },
          blendMode: BlendMode.srcIn,
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}

class ElectricalLoadingAnimation extends StatefulWidget {
  const ElectricalLoadingAnimation({
    required this.primaryColor,
    this.size = 160,
    super.key,
  });

  final Color primaryColor;
  final double size;

  @override
  State<ElectricalLoadingAnimation> createState() =>
      _ElectricalLoadingAnimationState();
}

class _ElectricalLoadingAnimationState extends State<ElectricalLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _PulseBoltPainter(
              progress: _controller.value,
              color: widget.primaryColor,
            ),
          );
        },
      ),
    );
  }
}

class _PulseBoltPainter extends CustomPainter {
  const _PulseBoltPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.shortestSide * 0.34;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var i = 0; i < 3; i++) {
      final local = (progress + (i * 0.33)) % 1.0;
      ringPaint.color = color.withValues(alpha: (1 - local) * 0.6);
      canvas.drawCircle(center, baseRadius + local * 34, ringPaint);
    }

    final boltPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.9);

    final pulse = 0.92 + (math.sin(progress * math.pi * 2) * 0.08);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulse, pulse);
    canvas.translate(-center.dx, -center.dy);

    final bolt = Path()
      ..moveTo(center.dx - 10, center.dy - 38)
      ..lineTo(center.dx + 2, center.dy - 38)
      ..lineTo(center.dx - 6, center.dy - 10)
      ..lineTo(center.dx + 12, center.dy - 10)
      ..lineTo(center.dx - 4, center.dy + 38)
      ..lineTo(center.dx + 1, center.dy + 6)
      ..lineTo(center.dx - 14, center.dy + 6)
      ..close();

    canvas.drawPath(bolt, boltPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PulseBoltPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class LoadingDots extends StatefulWidget {
  const LoadingDots({
    this.color = Colors.white,
    this.size = 5,
    super.key,
  });

  final Color color;
  final double size;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final active = (_controller.value * 3).floor() % 3;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final isActive = index <= active;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: isActive ? 1 : 0.35),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
