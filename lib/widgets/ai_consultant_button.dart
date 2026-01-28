import 'dart:ui'; // Required for PathMetric

import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AIConsultantButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AIConsultantButton({super.key, required this.onPressed});

  @override
  State<AIConsultantButton> createState() => _AIConsultantButtonState();
}

class _AIConsultantButtonState extends State<AIConsultantButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
        return CustomPaint(
          painter: _BorderPainter(animationValue: _controller.value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(2), // Padding for border width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14), // Outer radius
            ),
            child: ElevatedButton.icon(
              onPressed: widget.onPressed,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: Shimmer.fromColors(
                baseColor: Colors.black,
                highlightColor: Colors.lightGreenAccent,
                period: const Duration(seconds: 6),
                child: Text(
                  AppLocalizations.of(context)!.startWithAiConsultant,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0, // Remove elevation to blend with custom border
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BorderPainter extends CustomPainter {
  final double animationValue;

  _BorderPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Inset by 1.0 because strokeWidth is 2.0 (center is at 1.0)
    // This aligns the border to occupy pixels 0..2
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    // Radius should be 13 to match the center of the 2px gap (Outer 14, Inner 12)
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(13));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      final wormLength = length * 0.3;
      final start = length * animationValue;
      final end = start + wormLength;

      if (end <= length) {
        _drawGradientSegment(canvas, metric, start, end, wormLength, 0.0);
      } else {
        // Wrap around
        final firstSegmentLen = length - start;
        _drawGradientSegment(canvas, metric, start, length, wormLength, 0.0);
        _drawGradientSegment(
          canvas,
          metric,
          0,
          end - length,
          wormLength,
          firstSegmentLen,
        );
      }
    }
  }

  void _drawGradientSegment(
    Canvas canvas,
    PathMetric metric,
    double start,
    double end,
    double totalWormLength,
    double currentWormDist,
  ) {
    const double step = 2.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (double i = start; i < end; i += step) {
      final next = (i + step) > end ? end : (i + step);
      final pos1 = metric.getTangentForOffset(i)!.position;
      final pos2 = metric.getTangentForOffset(next)!.position;

      // Color logic: Gradient along the worm length
      // progress: 0.0 (tail) -> 1.0 (head)
      // Actually, since we draw start->end, and animation moves forward,
      // start is tail, end is head.
      // But we call standard drawing order.
      final distFromTail = currentWormDist + (i - start);
      final progress = distFromTail / totalWormLength;

      paint.color = _getGradientColor(progress);

      canvas.drawLine(pos1, pos2, paint);
    }
  }

  Color _getGradientColor(double t) {
    // Soft edges: fade in 0.0-0.2, solid 0.2-0.8, fade out 0.8-1.0
    // Colors: Blue -> Purple -> Red
    // We can use a linear interpolation manually or minimal logic.

    double opacity = 1.0;
    if (t < 0.2) {
      opacity = t / 0.2;
    } else if (t > 0.8) {
      opacity = (1.0 - t) / 0.2;
    }

    // Clamp opacity
    opacity = opacity.clamp(0.0, 1.0);

    // Color gradient
    // 0.0 - 0.5 : Blue -> Purple
    // 0.5 - 1.0 : Purple -> Red
    Color baseColor;
    if (t < 0.5) {
      final localT = t * 2;
      baseColor = Color.lerp(Colors.blue, Colors.purple, localT)!;
    } else {
      final localT = (t - 0.5) * 2;
      baseColor = Color.lerp(Colors.purple, Colors.red, localT)!;
    }

    return baseColor.withValues(alpha: opacity);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
