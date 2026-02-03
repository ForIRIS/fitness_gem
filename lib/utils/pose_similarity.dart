import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// PoseSimilarity - Compare pose similarity for Ready Pose
class PoseSimilarity {
  /// Calculate similarity between two poses (0.0 ~ 1.0)
  /// trainerPose: Standard pose (pre-captured coordinates)
  /// userPose: User's current pose
  static double compare(List<Point3D> trainerPose, Pose userPose) {
    if (trainerPose.isEmpty) return 0.0;

    // Extract and normalize vector from user pose
    final userVector = _extractAndNormalize(userPose);
    if (userVector.isEmpty) return 0.0;

    // Calculate cosine similarity
    return _cosineSimilarity(trainerPose, userVector);
  }

  /// Extract pose vector from ML Kit Pose
  static List<Point3D> extractPoseVector(Pose pose) {
    return _extractAndNormalize(pose);
  }

  /// Normalization: Set Hip as origin and scale to 1.0
  static List<Point3D> _extractAndNormalize(Pose pose) {
    final landmarks = pose.landmarks;
    if (landmarks.isEmpty) return [];

    // Extract only key landmarks
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

    // Calculate center point (Hip midpoint)
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftHip == null || rightHip == null) return [];

    final centerX = (leftHip.x + rightHip.x) / 2;
    final centerY = (leftHip.y + rightHip.y) / 2;

    // Calculate scale (based on Shoulder-Hip distance)
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftShoulder == null || rightShoulder == null) return [];

    final shoulderCenterY = (leftShoulder.y + rightShoulder.y) / 2;
    final torsoLength = (centerY - shoulderCenterY).abs();

    if (torsoLength < 1) return []; // Ignore if too small

    // Create normalized vector
    final normalizedPoints = <Point3D>[];

    for (final type in keyTypes) {
      final landmark = landmarks[type];
      if (landmark == null) {
        // Missing landmarks are set to 0
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

  /// Calculate cosine similarity
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

    // Convert -1 ~ 1 range to 0 ~ 1
    return (similarity + 1) / 2;
  }

  /// Convert extracted pose from image to storable format
  static Map<String, dynamic> poseToJson(Pose pose) {
    final vector = _extractAndNormalize(pose);
    return {
      'points': vector.map((p) => {'x': p.x, 'y': p.y, 'z': p.z}).toList(),
    };
  }

  /// Restore pose vector from JSON
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

/// 3D Point Class
class Point3D {
  final double x;
  final double y;
  final double z;

  Point3D(this.x, this.y, this.z);
}
