import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SmartWaitWidget - Progressive disclosure loading UI
/// Masks Gemini processing time with timer-based text cycling.
class SmartWaitWidget extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration totalDuration;

  const SmartWaitWidget({
    super.key,
    this.onComplete,
    this.totalDuration = const Duration(seconds: 5),
  });

  @override
  State<SmartWaitWidget> createState() => _SmartWaitWidgetState();
}

class _SmartWaitWidgetState extends State<SmartWaitWidget>
    with SingleTickerProviderStateMixin {
  static const _phases = [
    _Phase(
      text: 'Syncing workout data...',
      icon: Icons.sync,
      duration: Duration(milliseconds: 1500),
    ),
    _Phase(
      text: 'Comparing with your Baseline...',
      icon: Icons.compare_arrows,
      duration: Duration(milliseconds: 1500),
    ),
    _Phase(
      text: 'Generating performance insights...',
      icon: Icons.auto_awesome,
      duration: Duration(milliseconds: 1500),
    ),
  ];

  int _currentPhaseIndex = 0;
  Timer? _phaseTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _startPhaseTimer();
  }

  void _startPhaseTimer() {
    final currentPhase = _phases[_currentPhaseIndex];
    _phaseTimer = Timer(currentPhase.duration, () {
      if (_currentPhaseIndex < _phases.length - 1) {
        _fadeController.reverse().then((_) {
          if (mounted) {
            setState(() => _currentPhaseIndex++);
            _fadeController.forward();
            _startPhaseTimer();
          }
        });
      } else {
        // Completed all phases
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_currentPhaseIndex];

    return Container(
      color: Colors.black87,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.8, end: 1.0),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade400,
                            Colors.deepPurple.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(phase.icon, size: 48, color: Colors.white),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Phase Text
              Text(
                phase.text,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Progress Indicator
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: (_currentPhaseIndex + 1) / _phases.length,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation(
                    Colors.deepPurple.shade300,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Phase {
  final String text;
  final IconData icon;
  final Duration duration;

  const _Phase({
    required this.text,
    required this.icon,
    required this.duration,
  });
}
