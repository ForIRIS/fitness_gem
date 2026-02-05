import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Red Mode Content Widget
/// Displayed when an emergency is confirmed.
/// Shows pulsating red background, siren/TTS, SOS slider, and cancel button.
class RedModeContent extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSOS;

  const RedModeContent({
    super.key,
    required this.onCancel,
    required this.onSOS,
  });

  @override
  State<RedModeContent> createState() => _RedModeContentState();
}

class _RedModeContentState extends State<RedModeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final FlutterTts _flutterTts = FlutterTts();
  Timer? _ttsTimer;

  // SOS Slider
  double _sliderValue = 0.0;
  static const double _sosThreshold = 0.85;

  // Cancel Button
  bool _isCancelPressed = false;
  Timer? _cancelTimer;
  double _cancelProgress = 0.0;
  static const Duration _cancelHoldDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    // Pulsating animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start Audio Alert
    _startAudioAlert();

    // Strong haptic
    HapticFeedback.heavyImpact();
  }

  void _startAudioAlert() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Speak once immediately, then loop
    _speakWarning();
    _ttsTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _speakWarning();
      HapticFeedback.heavyImpact();
    });
  }

  void _speakWarning() {
    _flutterTts.speak("Emergency Detected. Help is on the way.");
  }

  void _stopAudioAlert() {
    _flutterTts.stop();
    _ttsTimer?.cancel();
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
    });

    if (value >= _sosThreshold) {
      _stopAudioAlert();
      widget.onSOS();
    }
  }

  void _onCancelStart() {
    setState(() {
      _isCancelPressed = true;
      _cancelProgress = 0.0;
    });

    _cancelTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _cancelProgress += 50 / _cancelHoldDuration.inMilliseconds;
      });

      if (_cancelProgress >= 1.0) {
        timer.cancel();
        _stopAudioAlert();
        widget.onCancel();
      }
    });
  }

  void _onCancelEnd() {
    _cancelTimer?.cancel();
    setState(() {
      _isCancelPressed = false;
      _cancelProgress = 0.0;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopAudioAlert();
    _cancelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          color: Color.lerp(
            Colors.red[900],
            Colors.red[600],
            _pulseAnimation.value,
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Warning Icon
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white.withValues(alpha: _pulseAnimation.value),
                  size: 100,
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  "EMERGENCY",
                  style: GoogleFonts.barlowCondensed(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Fall detected. Help is on the way.",
                  style: GoogleFonts.barlow(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                  ),
                ),

                const Spacer(flex: 2),

                // SOS Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        "Slide to Call SOS (119)",
                        style: GoogleFonts.barlow(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: Stack(
                          children: [
                            // Track fill
                            FractionallySizedBox(
                              widthFactor: _sliderValue,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(35),
                                ),
                              ),
                            ),
                            // Slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 70,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 30,
                                ),
                                overlayShape: SliderComponentShape.noOverlay,
                                activeTrackColor: Colors.transparent,
                                inactiveTrackColor: Colors.transparent,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: _sliderValue,
                                onChanged: _onSliderChanged,
                              ),
                            ),
                            // Arrow hint
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Cancel Button (Long Press)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: GestureDetector(
                    onTapDown: (_) => _onCancelStart(),
                    onTapUp: (_) => _onCancelEnd(),
                    onTapCancel: _onCancelEnd,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: _isCancelPressed
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress indicator
                          if (_isCancelPressed)
                            Positioned(
                              left: 0,
                              right: 0,
                              child: LinearProgressIndicator(
                                value: _cancelProgress,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                          Text(
                            "Hold to Cancel",
                            style: GoogleFonts.barlow(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
