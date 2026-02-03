import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'guardian_strategy.dart';

class OnboardingGuardianPage extends StatefulWidget {
  final bool fallDetectionEnabled;
  final Function(bool) onFallDetectionChanged;
  final TextEditingController guardianController;
  final Function(String) onPhoneChanged;
  final VoidCallback onSkip;

  const OnboardingGuardianPage({
    super.key,
    required this.fallDetectionEnabled,
    required this.onFallDetectionChanged,
    required this.guardianController,
    required this.onPhoneChanged,
    required this.onSkip,
  });

  @override
  State<OnboardingGuardianPage> createState() => _OnboardingGuardianPageState();
}

class _OnboardingGuardianPageState extends State<OnboardingGuardianPage> {
  late final GuardianStrategy _strategy;

  @override
  void initState() {
    super.initState();
    _strategy = GuardianStrategyFactory.getStrategy(Platform.isIOS);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Prevent keyboard overlap issues
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _strategy.getThemeColor().withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              _strategy.getIcon(),
              size: 64,
              color: _strategy.getThemeColor(),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _strategy.getTitle(context),
            textAlign: TextAlign.center,
            style: GoogleFonts.barlowCondensed(
              color: const Color(0xFF1A237E),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _strategy.getDescription(context),
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 48),

          // Strategy Content
          _strategy.buildContent(
            context,
            fallDetectionEnabled: widget.fallDetectionEnabled,
            onFallDetectionChanged: widget.onFallDetectionChanged,
            guardianController: widget.guardianController,
            onPhoneChanged: widget.onPhoneChanged,
          ),
        ],
      ),
    );
  }
}
