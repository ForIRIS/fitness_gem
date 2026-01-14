import 'dart:convert';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// ExerciseConfig - Rep 카운팅용 운동 설정
/// configureUrl에서 다운로드한 JSON으로 생성
class ExerciseConfig {
  final String id;
  final List<PoseLandmarkType> landmarks; // 분석할 관절들 (예: hip, knee, ankle)
  final double startThreshold; // 시작 자세 각도 임계값
  final double turnThreshold; // 턴 포인트 각도 임계값

  ExerciseConfig({
    required this.id,
    required this.landmarks,
    required this.startThreshold,
    required this.turnThreshold,
  });

  factory ExerciseConfig.fromMap(Map<String, dynamic> map) {
    // landmarks를 문자열 리스트에서 PoseLandmarkType으로 변환
    final landmarkStrings = (map['landmarks'] as List<dynamic>?) ?? [];
    final landmarks = landmarkStrings
        .map((str) => _stringToLandmarkType(str.toString()))
        .whereType<PoseLandmarkType>()
        .toList();

    return ExerciseConfig(
      id: map['id'] ?? '',
      landmarks: landmarks,
      startThreshold: (map['startThreshold'] ?? 160.0).toDouble(),
      turnThreshold: (map['turnThreshold'] ?? 90.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'landmarks': landmarks.map((l) => l.name).toList(),
      'startThreshold': startThreshold,
      'turnThreshold': turnThreshold,
    };
  }

  String toJson() => json.encode(toMap());

  factory ExerciseConfig.fromJson(String source) =>
      ExerciseConfig.fromMap(json.decode(source));

  /// 문자열을 PoseLandmarkType으로 변환
  static PoseLandmarkType? _stringToLandmarkType(String str) {
    final lower = str.toLowerCase();
    switch (lower) {
      case 'nose':
        return PoseLandmarkType.nose;
      case 'lefteye':
      case 'left_eye':
        return PoseLandmarkType.leftEye;
      case 'righteye':
      case 'right_eye':
        return PoseLandmarkType.rightEye;
      case 'leftear':
      case 'left_ear':
        return PoseLandmarkType.leftEar;
      case 'rightear':
      case 'right_ear':
        return PoseLandmarkType.rightEar;
      case 'leftshoulder':
      case 'left_shoulder':
        return PoseLandmarkType.leftShoulder;
      case 'rightshoulder':
      case 'right_shoulder':
        return PoseLandmarkType.rightShoulder;
      case 'leftelbow':
      case 'left_elbow':
        return PoseLandmarkType.leftElbow;
      case 'rightelbow':
      case 'right_elbow':
        return PoseLandmarkType.rightElbow;
      case 'leftwrist':
      case 'left_wrist':
        return PoseLandmarkType.leftWrist;
      case 'rightwrist':
      case 'right_wrist':
        return PoseLandmarkType.rightWrist;
      case 'lefthip':
      case 'left_hip':
        return PoseLandmarkType.leftHip;
      case 'righthip':
      case 'right_hip':
        return PoseLandmarkType.rightHip;
      case 'leftknee':
      case 'left_knee':
        return PoseLandmarkType.leftKnee;
      case 'rightknee':
      case 'right_knee':
        return PoseLandmarkType.rightKnee;
      case 'leftankle':
      case 'left_ankle':
        return PoseLandmarkType.leftAnkle;
      case 'rightankle':
      case 'right_ankle':
        return PoseLandmarkType.rightAnkle;
      default:
        return null;
    }
  }

  /// 기본 스쿼트 설정 (테스트용)
  static ExerciseConfig defaultSquat() {
    return ExerciseConfig(
      id: 'squat_default',
      landmarks: [
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
      ],
      startThreshold: 160.0, // 서있는 자세 (무릎 거의 펴짐)
      turnThreshold: 90.0, // 스쿼트 최저점 (무릎 90도)
    );
  }

  /// 기본 푸시업 설정 (테스트용)
  static ExerciseConfig defaultPushup() {
    return ExerciseConfig(
      id: 'pushup_default',
      landmarks: [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
      ],
      startThreshold: 160.0, // 팔 뻗은 자세
      turnThreshold: 90.0, // 팔굽혀 내린 자세
    );
  }

  /// 기본 런지 설정 (테스트용)
  static ExerciseConfig defaultLunge() {
    return ExerciseConfig(
      id: 'lunge_default',
      landmarks: [
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
      ],
      startThreshold: 160.0,
      turnThreshold: 90.0,
    );
  }
}
