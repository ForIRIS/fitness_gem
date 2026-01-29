import 'dart:math';

/// PoseNormalization - Utility for normalizing landmark coordinates.
///
/// Normalizes landmarks by centering on the hip center and scaling by torso length.
/// This ensures the model receives consistent scale and positioning regardless of
/// camera distance or person height.
class PoseNormalization {
  /// Normalize landmarks by torso scale and hip centering.
  /// landmarks: List of [x, y, z] triples (typically 33 points).
  static List<List<double>> normalizeByTorso(
    List<List<double>> landmarks, {
    double? scale,
  }) {
    if (landmarks.length < 25)
      return landmarks; // Safety check for indices 23, 24

    // Landmarks indices (ML Kit Pose Detection standard):
    // 23: left_hip, 24: right_hip
    // 11: left_shoulder, 12: right_shoulder

    final leftHip = landmarks[23];
    final rightHip = landmarks[24];

    // 1. Calculate Hip Center (Midpoint between left and right hip)
    final hipCenter = [
      (leftHip[0] + rightHip[0]) / 2,
      (leftHip[1] + rightHip[1]) / 2,
      (leftHip[2] + rightHip[2]) / 2,
    ];

    // 2. Offset: Center all landmarks relative to the hip center
    final offsetLandmarks = landmarks
        .map(
          (l) => [
            l[0] - hipCenter[0],
            l[1] - hipCenter[1],
            l[2] - hipCenter[2],
          ],
        )
        .toList();

    // 3. Scale Factor: Normalize by torso length
    double factor;
    if (scale != null) {
      factor = scale;
    } else {
      // midShoulder = Average of left and right shoulder offsets
      if (offsetLandmarks.length < 13)
        return offsetLandmarks; // Safety check for 11, 12

      final lShoulder = offsetLandmarks[11];
      final rShoulder = offsetLandmarks[12];

      final midShoulder = [
        (lShoulder[0] + rShoulder[0]) / 2,
        (lShoulder[1] + rShoulder[1]) / 2,
        (lShoulder[2] + rShoulder[2]) / 2,
      ];

      // Distance from hip center (at 0,0,0 now) to mid shoulder
      final dist = sqrt(
        midShoulder[0] * midShoulder[0] +
            midShoulder[1] * midShoulder[1] +
            midShoulder[2] * midShoulder[2],
      );

      // Avoid division by zero
      factor = dist > 1e-6 ? dist : 1.0;
    }

    // 4. Return Normalized Landmarks
    return offsetLandmarks
        .map((l) => [l[0] / factor, l[1] / factor, l[2] / factor])
        .toList();
  }
}
