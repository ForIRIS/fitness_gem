import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// FormRuleChecker - 실시간 자세 규칙 기반 피드백
/// 운동별 규칙을 정의하고 위반 시 짧은 피드백 메시지 반환
class FormRuleChecker {
  // 쿨다운 관리 (같은 경고 5초 내 반복 방지)
  final Map<String, DateTime> _lastWarningTimes = {};
  static const Duration _cooldownDuration = Duration(seconds: 5);

  // 현재 운동 설정
  String _currentExercise = '';

  /// 운동 설정
  void setExercise(String exercise) {
    _currentExercise = exercise.toLowerCase();
    _lastWarningTimes.clear();
  }

  /// 포즈 분석 및 피드백 반환
  /// 반환: 문제 발견 시 짧은 피드백 메시지, 없으면 null
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

    // 가장 심각한 위반 선택 (쿨다운 적용)
    for (final violation in violations) {
      if (_canShowWarning(violation.ruleId)) {
        _lastWarningTimes[violation.ruleId] = DateTime.now();
        return violation.shortMessage;
      }
    }

    return null;
  }

  /// 쿨다운 확인
  bool _canShowWarning(String ruleId) {
    final lastTime = _lastWarningTimes[ruleId];
    if (lastTime == null) return true;
    return DateTime.now().difference(lastTime) > _cooldownDuration;
  }

  // ============ 스쿼트 규칙 ============
  List<FormViolation> _checkSquatForm(Pose pose) {
    final violations = <FormViolation>[];

    // 무릎 각도 계산
    final leftKneeAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftKnee],
      pose.landmarks[PoseLandmarkType.leftAnkle],
    );

    // 허리 각도 (어깨-힙-무릎)
    final backAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftKnee],
    );

    // 무릎 내측 꺾임 (Knee Valgus) 감지
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];

    if (leftKnee != null && leftAnkle != null && leftHip != null) {
      // 무릎이 발목보다 안쪽으로 들어갔는지 확인
      if (leftKnee.x < leftAnkle.x - 20) {
        violations.add(
          FormViolation(
            ruleId: 'squat_knee_valgus',
            shortMessage: 'Knees out!', // "무릎 밖으로!"
            severity: 2,
          ),
        );
      }
    }

    // 과도한 전방 기울기
    if (backAngle != null && backAngle < 70) {
      violations.add(
        FormViolation(
          ruleId: 'squat_forward_lean',
          shortMessage: 'Chest up!', // "가슴 펴세요!"
          severity: 1,
        ),
      );
    }

    // 무릎이 발끝을 넘어감 (심한 경우만)
    final leftToe = pose.landmarks[PoseLandmarkType.leftFootIndex];
    if (leftKnee != null && leftToe != null) {
      if (leftKnee.y > leftToe.y + 50) {
        // Y축은 아래로 증가
        violations.add(
          FormViolation(
            ruleId: 'squat_knee_over_toe',
            shortMessage: 'Weight back!', // "무게 뒤로!"
            severity: 1,
          ),
        );
      }
    }

    violations.sort((a, b) => b.severity.compareTo(a.severity));
    return violations;
  }

  // ============ 푸시업 규칙 ============
  List<FormViolation> _checkPushupForm(Pose pose) {
    final violations = <FormViolation>[];

    // 팔꿈치 각도
    final elbowAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftElbow],
      pose.landmarks[PoseLandmarkType.leftWrist],
    );

    // 허리 처짐/들림 감지 (어깨-힙-발목 일직선)
    final bodyLineAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftAnkle],
    );

    // 허리 처짐
    if (bodyLineAngle != null && bodyLineAngle < 160) {
      violations.add(
        FormViolation(
          ruleId: 'pushup_hip_sag',
          shortMessage: 'Hips up!', // "엉덩이 올려!"
          severity: 2,
        ),
      );
    }

    // 허리 과도하게 들림
    if (bodyLineAngle != null && bodyLineAngle > 190) {
      violations.add(
        FormViolation(
          ruleId: 'pushup_hip_pike',
          shortMessage: 'Lower hips!', // "엉덩이 내려!"
          severity: 1,
        ),
      );
    }

    violations.sort((a, b) => b.severity.compareTo(a.severity));
    return violations;
  }

  // ============ 런지 규칙 ============
  List<FormViolation> _checkLungeForm(Pose pose) {
    final violations = <FormViolation>[];

    // 앞무릎 각도
    final frontKneeAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftKnee],
      pose.landmarks[PoseLandmarkType.leftAnkle],
    );

    // 무릎이 90도 이하로 과도하게 굽혀짐
    if (frontKneeAngle != null && frontKneeAngle < 80) {
      violations.add(
        FormViolation(
          ruleId: 'lunge_knee_too_deep',
          shortMessage: 'Not too deep!', // "너무 깊지 않게!"
          severity: 1,
        ),
      );
    }

    // 상체 기울기
    final torsoAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftEar],
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftHip],
    );

    if (torsoAngle != null && torsoAngle < 160) {
      violations.add(
        FormViolation(
          ruleId: 'lunge_lean_forward',
          shortMessage: 'Stay upright!', // "상체 세워!"
          severity: 1,
        ),
      );
    }

    violations.sort((a, b) => b.severity.compareTo(a.severity));
    return violations;
  }

  // ============ 플랭크 규칙 ============
  List<FormViolation> _checkPlankForm(Pose pose) {
    final violations = <FormViolation>[];

    // 몸 일직선 확인 (어깨-힙-발목)
    final bodyLineAngle = _calculateAngle(
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftAnkle],
    );

    // 허리 처짐
    if (bodyLineAngle != null && bodyLineAngle < 165) {
      violations.add(
        FormViolation(
          ruleId: 'plank_hip_sag',
          shortMessage: 'Engage core!', // "코어 힘줘!"
          severity: 2,
        ),
      );
    }

    // 엉덩이 들림
    if (bodyLineAngle != null && bodyLineAngle > 185) {
      violations.add(
        FormViolation(
          ruleId: 'plank_hip_pike',
          shortMessage: 'Lower hips!', // "엉덩이 내려!"
          severity: 1,
        ),
      );
    }

    violations.sort((a, b) => b.severity.compareTo(a.severity));
    return violations;
  }

  // ============ 각도 계산 유틸 ============
  double? _calculateAngle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) {
    if (a == null || b == null || c == null) return null;

    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    var angle = radians * 180 / pi;

    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;

    return angle;
  }

  /// 리셋
  void reset() {
    _lastWarningTimes.clear();
  }
}

/// 폼 위반 정보
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
