import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// PoseSimilarity - Ready Pose 유사도 비교
class PoseSimilarity {
  /// 두 포즈의 유사도 계산 (0.0 ~ 1.0)
  /// trainerPose: 정석 자세 (미리 캡처된 좌표)
  /// userPose: 사용자의 현재 포즈
  static double compare(List<Point3D> trainerPose, Pose userPose) {
    if (trainerPose.isEmpty) return 0.0;

    // 사용자 포즈에서 벡터 추출 및 정규화
    final userVector = _extractAndNormalize(userPose);
    if (userVector.isEmpty) return 0.0;

    // 코사인 유사도 계산
    return _cosineSimilarity(trainerPose, userVector);
  }

  /// ML Kit Pose에서 포즈 벡터 추출
  static List<Point3D> extractPoseVector(Pose pose) {
    return _extractAndNormalize(pose);
  }

  /// 정규화: Hip을 원점으로, 크기를 1.0으로 맞춤
  static List<Point3D> _extractAndNormalize(Pose pose) {
    final landmarks = pose.landmarks;
    if (landmarks.isEmpty) return [];

    // 주요 랜드마크만 추출
    final keyTypes = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    // 중심점 계산 (Hip 중간점)
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftHip == null || rightHip == null) return [];

    final centerX = (leftHip.x + rightHip.x) / 2;
    final centerY = (leftHip.y + rightHip.y) / 2;

    // 스케일 계산 (어깨-힙 거리 기준)
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftShoulder == null || rightShoulder == null) return [];

    final shoulderCenterY = (leftShoulder.y + rightShoulder.y) / 2;
    final torsoLength = (centerY - shoulderCenterY).abs();

    if (torsoLength < 1) return []; // 너무 작으면 무시

    // 정규화된 벡터 생성
    final normalizedPoints = <Point3D>[];

    for (final type in keyTypes) {
      final landmark = landmarks[type];
      if (landmark == null) {
        // 누락된 랜드마크는 0으로
        normalizedPoints.add(Point3D(0, 0, 0));
      } else {
        normalizedPoints.add(
          Point3D(
            (landmark.x - centerX) / torsoLength,
            (landmark.y - centerY) / torsoLength,
            landmark.z / torsoLength,
          ),
        );
      }
    }

    return normalizedPoints;
  }

  /// 코사인 유사도 계산
  static double _cosineSimilarity(List<Point3D> a, List<Point3D> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i].x * b[i].x + a[i].y * b[i].y;
      normA += a[i].x * a[i].x + a[i].y * a[i].y;
      normB += b[i].x * b[i].x + b[i].y * b[i].y;
    }

    if (normA == 0 || normB == 0) return 0.0;

    final similarity = dotProduct / (sqrt(normA) * sqrt(normB));

    // -1 ~ 1 범위를 0 ~ 1로 변환
    return (similarity + 1) / 2;
  }

  /// 이미지에서 포즈 추출하여 저장할 수 있는 형태로 변환
  static Map<String, dynamic> poseToJson(Pose pose) {
    final vector = _extractAndNormalize(pose);
    return {
      'points': vector.map((p) => {'x': p.x, 'y': p.y, 'z': p.z}).toList(),
    };
  }

  /// JSON에서 포즈 벡터 복원
  static List<Point3D> poseFromJson(Map<String, dynamic> json) {
    final points = json['points'] as List<dynamic>? ?? [];
    return points.map((p) {
      final map = p as Map<String, dynamic>;
      return Point3D(
        (map['x'] as num).toDouble(),
        (map['y'] as num).toDouble(),
        (map['z'] as num).toDouble(),
      );
    }).toList();
  }
}

/// 3D 포인트 클래스
class Point3D {
  final double x;
  final double y;
  final double z;

  Point3D(this.x, this.y, this.z);
}
