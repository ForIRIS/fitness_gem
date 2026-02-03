import 'dart:async';
import 'package:flutter/material.dart';

/// AnimatedLoadingText - Loading text with animated dots
/// Ex: "Loading." → "Loading.." → "Loading..." → "Loading."
class AnimatedLoadingText extends StatefulWidget {
  final String baseText;
  final TextStyle? style;
  final Duration interval;
  final int maxDots;

  const AnimatedLoadingText({
    super.key,
    required this.baseText,
    this.style,
    this.interval = const Duration(milliseconds: 500),
    this.maxDots = 3,
  });

  @override
  State<AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<AnimatedLoadingText> {
  int _dotCount = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(widget.interval, (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount % widget.maxDots) + 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    final padding = ' ' * (widget.maxDots - _dotCount); // Maintain width

    return Text('${widget.baseText}$dots$padding', style: widget.style);
  }
}
