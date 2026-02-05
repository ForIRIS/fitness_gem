import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:camera/camera.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

import '../core/di/injection.dart';
import '../domain/entities/user_profile.dart';
import '../domain/usecases/ai/analyze_fall_detection_usecase.dart';
import '../services/camera_manager.dart';
import 'emergency_notification_service.dart';
import 'incident_log_service.dart';

/// State for the emergency flow
enum EmergencyFlowState {
  /// Normal workout, no emergency detected
  inactive,

  /// Fall suspected, waiting for user response or Gemini analysis
  amber,

  /// Emergency confirmed, siren active, awaiting SOS or cancel
  red,
}

/// Manages the emergency flow state machine.
/// Handles transitions between inactive → amber → red states.
class EmergencyFlowManager extends ChangeNotifier {
  EmergencyFlowState _state = EmergencyFlowState.inactive;
  EmergencyFlowState get state => _state;

  // Timers
  Timer? _geminiTimeoutTimer;
  static const Duration _geminiTimeout = Duration(seconds: 10);

  // Dependencies
  final AnalyzeFallDetectionUseCase _analyzeFallDetection =
      getIt<AnalyzeFallDetectionUseCase>();
  final EmergencyNotificationService _notificationService =
      EmergencyNotificationService();
  final IncidentLogService _incidentLog = IncidentLogService();

  // Context for analysis

  // Context for analysis
  UserProfile? _userProfile;
  CameraManager? _cameraManager;
  String? _capturedVideoPath;
  AppLocalizations? _l10n;

  /// Initialize with context needed for analysis and notifications.
  void initialize({
    required UserProfile userProfile,
    CameraManager? cameraManager,
    AppLocalizations? l10n,
  }) {
    _userProfile = userProfile;
    _cameraManager = cameraManager;
    _l10n = l10n;
  }

  /// Transition to Amber state when on-device detection triggers.
  Future<void> startAmber() async {
    if (_state != EmergencyFlowState.inactive) return;

    _state = EmergencyFlowState.amber;
    notifyListeners();

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Capture video for Gemini analysis
    await _captureVideoForAnalysis();

    // Log Start
    _incidentLog.logIncident(type: 'amber', status: 'triggered');

    // Start Gemini analysis with timeout
    _startGeminiAnalysis();
  }

  Future<void> _captureVideoForAnalysis() async {
    // If we have a camera manager, capture a snapshot (Image)
    // We use a snapshot instead of video to avoid interrupting any ongoing workout recording.
    // Gemini handles single images for fall verification well.
    if (_cameraManager != null && _cameraManager!.isInitialized) {
      try {
        final XFile file = await _cameraManager!.controller!.takePicture();
        _capturedVideoPath = file.path;
        debugPrint(
          '[EmergencyFlow] Captured snapshot for analysis: $_capturedVideoPath',
        );
      } catch (e) {
        debugPrint('[EmergencyFlow] Failed to capture snapshot: $e');
        _capturedVideoPath = null;
      }
    } else {
      _capturedVideoPath = null;
    }
  }

  void _startGeminiAnalysis() {
    // Start timeout timer
    _geminiTimeoutTimer?.cancel();
    _geminiTimeoutTimer = Timer(_geminiTimeout, () {
      // Timeout - escalate to red
      if (_state == EmergencyFlowState.amber) {
        debugPrint('[EmergencyFlow] Gemini timeout, escalating to RED');
        _transitionToRed();
      }
    });

    // Run Gemini analysis in background
    _runGeminiAnalysis();
  }

  Future<void> _runGeminiAnalysis() async {
    if (_capturedVideoPath == null || _userProfile == null) {
      debugPrint('[EmergencyFlow] No video or profile, waiting for timeout');
      return;
    }

    final result = await _analyzeFallDetection.execute(
      AnalyzeFallDetectionParams(
        videoFile: File(_capturedVideoPath!),
        profile: _userProfile!,
      ),
    );

    // Only process if still in amber state
    if (_state != EmergencyFlowState.amber) return;

    result.fold(
      (failure) {
        debugPrint(
          '[EmergencyFlow] Gemini analysis failed: ${failure.message}',
        );
        // On failure, let timeout handle escalation
      },
      (isDanger) {
        _geminiTimeoutTimer?.cancel();
        if (isDanger) {
          debugPrint('[EmergencyFlow] Gemini confirmed DANGER');
          _transitionToRed();
        } else {
          debugPrint('[EmergencyFlow] Gemini confirmed SAFE');
          _transitionToInactive();
        }
      },
    );
  }

  /// User dismissed the warning (tapped "I'm OK" during Amber)
  void userDismissed() {
    if (_state != EmergencyFlowState.amber) return;

    debugPrint('[EmergencyFlow] User dismissed amber warning');
    _incidentLog.logIncident(type: 'amber', status: 'dismissed_by_user');
    _geminiTimeoutTimer?.cancel();
    _transitionToInactive();
  }

  /// Cancel the emergency (long-press during Red mode)
  void cancelEmergency() {
    if (_state != EmergencyFlowState.red) return;

    debugPrint('[EmergencyFlow] User cancelled emergency');
    _incidentLog.logIncident(type: 'red', status: 'cancelled_by_user');
    _transitionToInactive();
  }

  /// Initiate SOS call
  Future<void> callSOS() async {
    debugPrint('[EmergencyFlow] Initiating SOS call');

    // Use appropriate emergency number based on locale
    // Use appropriate emergency number based on locale
    // Default to 112 (GSM standard) if unknown
    String number = '112';

    if (!kIsWeb) {
      try {
        final locale = Platform.localeName; // e.g., en_US, ko_KR
        if (locale.contains('KR')) {
          number = '119';
        } else if (locale.contains('US') || locale.contains('CA')) {
          number = '911';
        } else if (locale.contains('GB')) {
          number = '999';
        } else if (locale.contains('JP')) {
          number = '119';
        }
      } catch (e) {
        debugPrint('Error detecting locale for SOS: $e');
      }
    }

    final emergencyNumber = 'tel:$number';

    final uri = Uri.parse(emergencyNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      _incidentLog.logIncident(type: 'red', status: 'sos_called');
    }
  }

  void _transitionToRed() {
    _state = EmergencyFlowState.red;
    notifyListeners();

    // Trigger guardian notification
    if (_userProfile != null && _l10n != null) {
      _notificationService.triggerEmergency(_userProfile!, _l10n!);
    }

    _incidentLog.logIncident(type: 'red', status: 'escalated_to_emergency');

    // Strong haptic feedback
    HapticFeedback.heavyImpact();
  }

  void _transitionToInactive() {
    _state = EmergencyFlowState.inactive;
    _capturedVideoPath = null;
    notifyListeners();
  }

  /// Reset to inactive state (for cleanup)
  void reset() {
    _geminiTimeoutTimer?.cancel();
    _state = EmergencyFlowState.inactive;
    _capturedVideoPath = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _geminiTimeoutTimer?.cancel();
    super.dispose();
  }
}
