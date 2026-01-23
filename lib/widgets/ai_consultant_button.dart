import 'dart:math';

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
      duration: const Duration(seconds: 3),
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
                period: const Duration(seconds: 2),
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
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // Create a sweep gradient that rotates
    final Gradient gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: pi * 2,
      colors: const [
        Colors.transparent,
        Colors.transparent,
        Colors.red,
        Colors.blue,
        Colors.transparent,
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.45, 0.55, 0.7, 1.0],
      transform: GradientRotation(animationValue * pi * 2),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
