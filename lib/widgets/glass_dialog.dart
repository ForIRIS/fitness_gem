import 'dart:ui';
import 'package:flutter/material.dart';

class GlassDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget> actions;
  final Widget? icon;

  const GlassDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: (value - 0.8) * 5.0, // Maps 0.8-1.0 to 0.0-1.0
              child: child,
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(height: 16)],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12,
                    children: actions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.red.withOpacity(0.8)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? Colors.redAccent : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
