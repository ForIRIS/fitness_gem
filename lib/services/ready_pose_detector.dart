import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/rep_counter.dart';

class ReadyPoseResult {
  final bool isBodyVisible;
  final int holdSeconds;
  final bool isReady;

  const ReadyPoseResult({
    required this.isBodyVisible,
    required this.holdSeconds,
    required this.isReady,
  });
}

class ReadyPoseDetector {
  static const int requiredHoldSeconds = 5;
  static const int noiseToleranceMs = 500;
  static const double minLikelihood = 0.3;

  DateTime? _holdStartTime;
  DateTime? _lastReadySignalTime;
  DateTime? _lastDebugLogTime;

  ReadyPoseResult processFrame(Pose pose, RepCounter? repCounter) {
    final isBodyVisible = _checkBodyVisibility(pose);

    if (!isBodyVisible) {
      // Reset if body not visible
      _holdStartTime = null;
      return const ReadyPoseResult(
        isBodyVisible: false,
        holdSeconds: 0,
        isReady: false,
      );
    }

    // Use RepCounter's specific "Ready" class detection if available
    // or fallback to just standing still (Body Visible) if specific Ready pose not defined
    bool isReadyPoseDetected;

    if (repCounter == null) {
      // Model not loaded yet -> Wait (False) rather than risk false positive
      isReadyPoseDetected = false;
    } else if (repCounter.canDetectClass('Ready')) {
      // Strict check: Exercise has a "Ready" class, so we MUST detect it
      isReadyPoseDetected = repCounter.isClassDetected('Ready', threshold: 0.6);
    } else {
      // Fallback: Exercise has no "Ready" class (e.g. simple timer), just check visibility
      isReadyPoseDetected = true;
    }

    final now = DateTime.now();
    final shouldLog =
        _lastDebugLogTime == null ||
        now.difference(_lastDebugLogTime!).inSeconds >= 2;

    if (isReadyPoseDetected) {
      _lastReadySignalTime = now;
      _holdStartTime ??= now;
      if (shouldLog) {
        _lastDebugLogTime = now;
        debugPrint(
          "Ready Pose Holding... ${(now.difference(_holdStartTime!).inMilliseconds / 1000).toStringAsFixed(1)}s",
        );
      }
    } else {
      // Signal lost Logic with noise tolerance
      if (shouldLog) {
        _lastDebugLogTime = now;
        debugPrint(
          "Ready Pose Signal Lost. Previous hold: ${_holdStartTime != null}",
        );
      }
      if (_lastReadySignalTime != null) {
        final silenceDuration = now
            .difference(_lastReadySignalTime!)
            .inMilliseconds;
        if (silenceDuration > noiseToleranceMs) {
          _holdStartTime = null;
        }
        // If within noise tolerance, keep holding (don't reset start time)
      } else {
        _holdStartTime = null;
      }
    }

    int holdSeconds = 0;
    if (_holdStartTime != null) {
      holdSeconds = now.difference(_holdStartTime!).inSeconds;
    }

    return ReadyPoseResult(
      isBodyVisible: true,
      holdSeconds: holdSeconds,
      isReady: holdSeconds >= requiredHoldSeconds,
    );
  }

  void reset() {
    _holdStartTime = null;
    _lastReadySignalTime = null;
  }

  bool _checkBodyVisibility(Pose pose) {
    final requiredLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    int visibleCount = 0;
    for (final type in requiredLandmarks) {
      final landmark = pose.landmarks[type];
      if (landmark != null && landmark.likelihood >= minLikelihood) {
        visibleCount++;
      }
    }

    final visible = visibleCount >= 5;
    if (!visible) {
      debugPrint(
        'Body visibility: $visibleCount/8 landmarks (need 5, likelihood >= $minLikelihood)',
      );
    }
    return visible;
  }
}
