import 'dart:async';
import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'gemini_service.dart';
import '../models/user_profile.dart';

/// FallDetectionService - Fall detection service
/// Detects and responds to suspected fall situations during exercise
class FallDetectionService {
  // Settings
  static const double _headDropThreshold =
      0.3; // Drop more than 30% of screen height
  static const int _noMovementDurationMs = 5000; // No movement for 5 seconds
  static const double _movementThreshold = 20.0; // Movement threshold in pixels

  // State
  double? _previousHeadY;
  double? _referenceHeadY;
  DateTime? _lastMovementTime;
  bool _isFallSuspected = false;
  bool _isMonitoring = false;

  // Fall detection callbacks
  void Function()? onFallSuspected;
  void Function(bool confirmed)? onFallConfirmed;

  // Gemini service
  final GeminiService _geminiService = GeminiService();

  /// Start monitoring
  void startMonitoring() {
    _isMonitoring = true;
    _isFallSuspected = false;
    _previousHeadY = null;
    _referenceHeadY = null;
    _lastMovementTime = DateTime.now();
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _isFallSuspected = false;
  }

  /// Process pose and detect fall
  /// Returns: True if a fall is suspected
  bool processPose(Pose pose, double screenHeight, String currentExercise) {
    if (!_isMonitoring || _isFallSuspected) return false;

    // Exclude lying exercises from fall detection
    if (_isLyingExercise(currentExercise)) return false;

    // Extract head position
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];

    double? headY;
    if (nose != null) {
      headY = nose.y;
    } else if (leftEar != null && rightEar != null) {
      headY = (leftEar.y + rightEar.y) / 2;
    } else {
      return false;
    }

    // Set reference head position (first frame)
    _referenceHeadY ??= headY;

    // Detect movement
    if (_previousHeadY != null) {
      final movement = (headY - _previousHeadY!).abs();
      if (movement > _movementThreshold) {
        _lastMovementTime = DateTime.now();
      }
    }

    // Detect rapid head drop
    final headDrop = headY - (_referenceHeadY ?? headY);
    final dropRatio = headDrop / screenHeight;

    if (dropRatio > _headDropThreshold) {
      // Head dropped rapidly + check for unresponsiveness
      final timeSinceLastMovement = DateTime.now().difference(
        _lastMovementTime ?? DateTime.now(),
      );

      if (timeSinceLastMovement.inMilliseconds > _noMovementDurationMs) {
        // Fall suspected!
        _isFallSuspected = true;
        onFallSuspected?.call();
        return true;
      }
    }

    _previousHeadY = headY;
    return false;
  }

  /// Check if it's a lying exercise
  bool _isLyingExercise(String exercise) {
    final lower = exercise.toLowerCase();
    return lower.contains('plank') ||
        lower.contains('crunch') ||
        lower.contains('sit-up') ||
        lower.contains('dead bug') ||
        lower.contains('bridge');
  }

  /// Handle user response (confirm button click)
  void userResponded() {
    _isFallSuspected = false;
    _referenceHeadY = null; // Reset reference position
    _lastMovementTime = DateTime.now();
  }

  /// Request Gemini analysis on timeout
  Future<bool> analyzeWithGemini({
    required File videoFile,
    required UserProfile profile,
  }) async {
    final isFall = await _geminiService.analyzeFallDetection(
      videoFile: videoFile,
      profile: profile,
    );

    onFallConfirmed?.call(isFall);
    return isFall;
  }

  /// Reset fall detection state
  void reset() {
    _isFallSuspected = false;
    _previousHeadY = null;
    _referenceHeadY = null;
    _lastMovementTime = DateTime.now();
  }

  /// Current fall suspected status
  bool get isFallSuspected => _isFallSuspected;

  /// Whether monitoring is active
  bool get isMonitoring => _isMonitoring;
}
