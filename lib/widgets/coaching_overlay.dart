import 'package:flutter/material.dart';
import '../services/coaching_management_service.dart';

class CoachingOverlay extends StatefulWidget {
  const CoachingOverlay({super.key});

  @override
  State<CoachingOverlay> createState() => _CoachingOverlayState();
}

class _CoachingOverlayState extends State<CoachingOverlay>
    with SingleTickerProviderStateMixin {
  final CoachingManagementService _cms = CoachingManagementService();
  CoachingMessage? _currentMessage;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _cms.messageStream.listen((message) {
      if (!mounted) return;

      if (message != null) {
        setState(() {
          _currentMessage = message;
        });
        _animationController.forward(from: 0.0).then((_) {
          // After appearing, stay for 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _currentMessage == message) {
              _animationController.reverse();
            }
          });
        });
      } else {
        // null message means clear
        if (_animationController.status != AnimationStatus.dismissed) {
          _animationController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMessage == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _opacityAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepPurpleAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurpleAccent.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tips_and_updates,
                color: Colors.amberAccent,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                _currentMessage!.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
