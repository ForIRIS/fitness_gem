import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// FormRuleChecker - Real-time rule-based posture feedback
/// Defines exercise-specific rules and returns short feedback messages on violation
class FormRuleChecker {
  // Cooldown management (prevents the same warning from repeating within 5 seconds)
  final Map<String, DateTime> _lastWarningTimes = {};
  static const Duration _cooldownDuration = Duration(seconds: 5);

  // Current exercise configuration
  String _currentExercise = "";

  /// Set the exercise to check
  void setExercise(String exercise) {
    _currentExercise = exercise.toLowerCase();
    _lastWarningTimes.clear();
  }

  /// Analyze pose and return feedback
  /// Returns: A short feedback message if an issue is found, otherwise null
  String? checkForm(Pose pose) {
    if (_currentExercise.isEmpty) return null;

    List<FormViolation> violations = [];

    if (_currentExercise.contains('squat')) {
      violations.addAll(_checkSquatForm(pose));
    } else if (_currentExercise.contains('push')) {
      violations.addAll(_checkPushupForm(pose));
    } else if (_currentExercise.contains('lunge')) {
      violations.addAll(_checkLungeForm(pose));
    } else if (_currentExercise.contains('plank')) {
      violations.addAll(_checkPlankForm(pose));
    }

    // Select the most severe violation (applying cooldown)
    for (final violation in violations) {
      if (_canShowWarning(violation.ruleId)) {
        _lastWarningTimes[violation.ruleId] = DateTime.now();
        return violation.shortMessage;
      }
    }

    return null;
  }

  /// Check if a warning can be shown (cooldown check)
  bool _canShowWarning(String ruleId) {
    final lastTime = _lastWarningTimes[ruleId];
    if (lastTime == null) return true;
    return DateTime.now().difference(lastTime) > _cooldownDuration;
  }

  // ============ Squat Rules ============
  List<FormViolation> _checkSquatForm(Pose pose) {
    final violations = <FormViolation>[];

    // Calculate knee angle
    // This variable was unused and has been removed.

    // Back angle (Shoulder-Hip-Knee)
    final backAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftKnee],
    );

    // Detect Knee Valgus (knee inward collapse)
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];

    if (leftKnee != null && leftAnkle != null && leftHip != null) {
      // Check if knee is inward relative to the ankle
      if (leftKnee.x < leftAnkle.x - 20) {
        violations.add(
          FormViolation(
            ruleId: 'squat_knee_valgus',
            shortMessage: 'Knees out!',
            severity: 2,
          ),
        );
      }
    }

    // Excessive forward lean
    if (backAngle != null && backAngle < 70) {
      violations.add(
        FormViolation(
          ruleId: 'squat_forward_lean',
          shortMessage: 'Chest up!',
          severity: 1,
        ),
      );
    }

    // Knees over toes (only if severe)
    final leftToe = pose.landmarks[PoseLandmarkType.leftFootIndex];
    if (leftKnee != null && leftToe != null) {
      if (leftKnee.y > leftToe.y + 50) {
        // Y increases downwards
        violations.add(
          FormViolation(
            ruleId: 'squat_knee_over_toe',
            shortMessage: 'Weight back!',
            severity: 1,
          ),
        );
      }
    }

    violations.sort((a, b) => b.severity.compareTo(a.severity));
    return violations;
  }

  // ============ Push-up Rules ============
  List<FormViolation> _checkPushupForm(Pose pose) {
    final violations = <FormViolation>[];

    // Elbow angle
    // This variable was unused and has been removed.

    // Detect hip sag/pike (Shoulder-Hip-Ankle alignment)
    final bodyLineAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftAnkle],
    );

    // Hip sag
    if (bodyLineAngle != null && bodyLineAngle < 160) {
      violations.add(
        FormViolation(
          ruleId: 'pushup_hip_sag',
          shortMessage: 'Hips up!',
          severity: 2,
        ),
      );
    }

    // Hip pike (too high)
    if (bodyLineAngle != null && bodyLineAngle > 190) {
      violations.add(
        FormViolation(
          ruleId: 'pushup_hip_pike',
          shortMessage: 'Lower hips!',
          severity: 1,
        ),
      );
    }

    violations.sort((a, b) => b.severity.compareTo(a.severity));
    return violations;
  }

  // ============ Lunge Rules ============
  List<FormViolation> _checkLungeForm(Pose pose) {
    final violations = <FormViolation>[];

    // Front knee angle
    final frontKneeAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftKnee],
      pose.landmarks[PoseLandmarkType.leftAnkle],
    );

    // Knee bending too deeply (> 90 degrees)
    if (frontKneeAngle != null && frontKneeAngle < 80) {
      violations.add(
        FormViolation(
          ruleId: 'lunge_knee_too_deep',
          shortMessage: 'Not too deep!',
          severity: 1,
        ),
      );
    }

    // Torso lean
    final torsoAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftEar],
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftHip],
    );

    if (torsoAngle != null && torsoAngle < 160) {
      violations.add(
        FormViolation(
          ruleId: 'lunge_lean_forward',
          shortMessage: 'Stay upright!',
          severity: 1,
        ),
      );
    }

    violations.sort((a, b) => b.severity.compareTo(a.severity));
    return violations;
  }

  // ============ Plank Rules ============
  List<FormViolation> _checkPlankForm(Pose pose) {
    final violations = <FormViolation>[];

    // Body alignment (Shoulder-Hip-Ankle)
    final bodyLineAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftAnkle],
    );

    // Hip sag
    if (bodyLineAngle != null && bodyLineAngle < 165) {
      violations.add(
        FormViolation(
          ruleId: 'plank_hip_sag',
          shortMessage: 'Engage core!',
          severity: 2,
        ),
      );
    }

    // Hip pike
    if (bodyLineAngle != null && bodyLineAngle > 185) {
      violations.add(
        FormViolation(
          ruleId: 'plank_hip_pike',
          shortMessage: 'Lower hips!',
          severity: 1,
        ),
      );
    }

    violations.sort((a, b) => b.severity.compareTo(a.severity));
    return violations;
  }

  // ============ Angle Calculation Utility ============
  double? _calculateAngle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) {
    if (a == null || b == null || c == null) return null;

    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    var angle = radians * 180 / pi;

    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;

    return angle;
  }

  /// Reset checker
  void reset() {
    _lastWarningTimes.clear();
  }
}

/// Form violation info
class FormViolation {
  final String ruleId;
  final String shortMessage;
  final int severity; // 1: mild, 2: moderate, 3: severe

  FormViolation({
    required this.ruleId,
    required this.shortMessage,
    required this.severity,
  });
}
