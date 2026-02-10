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
  static const int noiseToleranceMs = 100;
  static const double minLikelihood = 0.5;

  DateTime? _holdStartTime;
  DateTime? _lastReadySignalTime;

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
    final bool isReadyPoseDetected =
        repCounter?.isClassDetected('Ready', threshold: 0.8) ?? true;

    final now = DateTime.now();

    if (isReadyPoseDetected) {
      _lastReadySignalTime = now;
      _holdStartTime ??= now;
      if (now.second % 2 == 0) {
        debugPrint(
          "Ready Pose Holding... ${(now.difference(_holdStartTime!).inMilliseconds / 1000).toStringAsFixed(1)}s",
        );
      }
    } else {
      // Signal lost Logic with noise tolerance
      debugPrint(
        "Ready Pose Signal Lost. Previous hold: ${_holdStartTime != null}",
      );
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

    // OK if 6 or more out of 8 are visible
    return visibleCount >= 6;
  }
}
