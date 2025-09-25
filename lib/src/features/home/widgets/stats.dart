import 'dart:math' as math;
import 'package:flutter/material.dart';

class StatRing extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const StatRing({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              return CustomPaint(
                size: const Size(70, 70),
                painter: _RingPainter(progress: t, color: color),
                child: Center(
                  child: Text(
                    "$value",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2;

    // background circle
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white12;
    canvas.drawCircle(center, radius - stroke / 2, bg);

    // progress arc
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        colors: [color.withValues(alpha:0.15), color, color],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final sweep = 2 * math.pi * progress * 0.85; // 85% ring
    final start = -math.pi / 2;
    final arcRect = Rect.fromCircle(
      center: center,
      radius: radius - stroke / 2,
    );
    canvas.drawArc(arcRect, start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
