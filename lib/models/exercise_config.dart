import 'dart:convert';
import 'package:flutter/foundation.dart';

/// ExerciseConfig - Exercise settings for Rep counting
/// Created from JSON downloaded from configureUrl
class ExerciseConfig {
  final String id;
  final Map<String, dynamic>? classLabels;
  final Map<String, dynamic>? medianStats;
  final Map<String, dynamic>? coachingCues;

  ExerciseConfig({
    required this.id,
    this.classLabels,
    this.medianStats,
    this.coachingCues,
  });

  factory ExerciseConfig.fromMap(Map<String, dynamic> map) {
    return ExerciseConfig(
      id: map['id'] ?? '',
      classLabels: map['class_labels'],
      medianStats: map['median_stats'],
      coachingCues: map['coaching_cues'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_labels': classLabels,
      'median_stats': medianStats,
      'coaching_cues': coachingCues,
    };
  }

  String toJson() => json.encode(toMap());

  factory ExerciseConfig.fromJson(String source) =>
      ExerciseConfig.fromMap(json.decode(source));

  /// Default Squat settings (for testing)
  static ExerciseConfig defaultSquat() {
    return ExerciseConfig(id: 'squat_default');
  }

  /// Default Push-up settings (for testing)
  static ExerciseConfig defaultPushup() {
    return ExerciseConfig(id: 'pushup_default');
  }

  /// Default Lunge settings (for testing)
  static ExerciseConfig defaultLunge() {
    return ExerciseConfig(id: 'lunge_default');
  }

  /// Default Plank settings (for testing)
  static ExerciseConfig defaultPlank() {
    return ExerciseConfig(id: 'plank_default');
  }

  ExerciseConfig copyWith({
    String? id,
    Map<String, dynamic>? classLabels,
    Map<String, dynamic>? medianStats,
    Map<String, dynamic>? coachingCues,
  }) {
    return ExerciseConfig(
      id: id ?? this.id,
      classLabels: classLabels ?? this.classLabels,
      medianStats: medianStats ?? this.medianStats,
      coachingCues: coachingCues ?? this.coachingCues,
    );
  }

  /// Get feature keys based on the feature set in classLabels
  List<String> get featureKeys {
    final featureSetName = classLabels?['feature_set'] as String?;
    if (featureSetName == null) return [];
    return getFeatureKeys(featureSetName);
  }
}

/// FeatureGroups - Atomic definitions of feature groups (Transcribed from Python)
class FeatureGroups {
  static const List<String> anglesUpper = [
    'shoulder_elbow_wrist_l',
    'shoulder_elbow_wrist_r',
    'hip_shoulder_elbow_l',
    'hip_shoulder_elbow_r',
    'elbow_wrist_index_l',
    'elbow_wrist_index_r',
    'torso_neck_angle',
  ];

  static const List<String> anglesLower = [
    'shoulder_hip_knee_l',
    'shoulder_hip_knee_r',
    'hip_knee_ankle_l',
    'hip_knee_ankle_r',
    'knee_ankle_foot_l',
    'knee_ankle_foot_r',
    'hip_abduction',
  ];

  static const List<String> anglesCore = [
    'torso_twist_ratio',
    'torso_bend',
    'torso_shin_parallelism',
  ];

  static const List<String> velocityUpper = [
    'velocity_wrist_l',
    'velocity_wrist_r',
    'velocity_elbow_l',
    'velocity_elbow_r',
    'velocity_shoulder_l',
    'velocity_shoulder_r',
  ];

  static const List<String> velocityLower = [
    'velocity_hip_l',
    'velocity_hip_r',
    'velocity_knee_l',
    'velocity_knee_r',
    'velocity_ankle_l',
    'velocity_ankle_r',
  ];

  static const List<String> accelUpper = [
    'acceleration_wrist_l',
    'acceleration_wrist_r',
    'acceleration_elbow_l',
    'acceleration_elbow_r',
  ];

  static const List<String> accelLower = [
    'acceleration_hip_l',
    'acceleration_hip_r',
    'acceleration_knee_l',
    'acceleration_knee_r',
    'acceleration_ankle_l',
    'acceleration_ankle_r',
  ];

  static const List<String> velocity3DHands = [
    'velocity_wrist_l_x',
    'velocity_wrist_l_y',
    'velocity_wrist_l_z',
    'velocity_wrist_r_x',
    'velocity_wrist_r_y',
    'velocity_wrist_r_z',
  ];

  static const List<String> velocity3DFeet = [
    'velocity_ankle_l_x',
    'velocity_ankle_l_y',
    'velocity_ankle_l_z',
    'velocity_ankle_r_x',
    'velocity_ankle_r_y',
    'velocity_ankle_r_z',
  ];

  static const List<String> spatialPosture = [
    'torso_verticality',
    'depth_ratio',
    'torso_lean',
    'spine_curvature',
  ];

  static const List<String> spatialLegs = [
    'shin_l_verticality',
    'shin_r_verticality',
    'thigh_l_verticality',
    'thigh_r_verticality',
  ];

  static const List<String> spatialLevel = ['hip_ankle_y_diff'];

  static const List<String> injuryKnees = [
    'knee_valgus_l',
    'knee_valgus_r',
    'hyperextension_knee_l',
    'hyperextension_knee_r',
  ];

  static const List<String> injuryElbows = [
    'hyperextension_elbow_l',
    'hyperextension_elbow_r',
  ];

  static const List<String> injurySpine = [
    'pelvic_tilt',
    'symmetry_upper',
    'symmetry_lower',
    'weight_shift_lateral',
  ];

  static const List<String> visibilityFull = [
    'visibility_shoulder_l',
    'visibility_shoulder_r',
    'visibility_elbow_l',
    'visibility_elbow_r',
    'visibility_wrist_l',
    'visibility_wrist_r',
    'visibility_hip_l',
    'visibility_hip_r',
    'visibility_knee_l',
    'visibility_knee_r',
    'visibility_ankle_l',
    'visibility_ankle_r',
  ];

  static const List<String> meta = ['motion_magnitude', 'temporal_consistency'];

  static List<String> getCosineKeys(List<String> angleList) {
    return angleList
        .where((k) => !k.contains('twist'))
        .map((k) => 'cosine_$k')
        .toList();
  }
}

/// FeatureAssembler - Helper to construct optimized feature sets
class FeatureAssembler {
  final Set<String> _features = {};

  FeatureAssembler add(List<String> group) {
    _features.addAll(group);
    return this;
  }

  FeatureAssembler addAngles(List<String> group, {bool includeCosine = true}) {
    _features.addAll(group);
    if (includeCosine) {
      _features.addAll(FeatureGroups.getCosineKeys(group));
    }
    return this;
  }

  List<String> build() {
    final list = _features.toList();
    list.sort();
    return list;
  }
}

/// Returns optimized feature sets based on Motion Patterns
List<String> getFeatureKeys(String featureSetName) {
  final assembler = FeatureAssembler();

  switch (featureSetName) {
    case 'strength_legs':
      return assembler
          .addAngles(FeatureGroups.anglesLower)
          .addAngles(FeatureGroups.anglesCore)
          .add(FeatureGroups.velocityLower)
          .add(FeatureGroups.injuryKnees)
          .add(FeatureGroups.injurySpine)
          .add(FeatureGroups.spatialLegs)
          .add(['torso_verticality', 'pelvic_tilt'])
          .build();

    case 'strength_upper':
      return assembler
          .addAngles(FeatureGroups.anglesUpper)
          .addAngles(FeatureGroups.anglesCore)
          .add(FeatureGroups.velocityUpper)
          .add(FeatureGroups.injuryElbows)
          .add(FeatureGroups.injurySpine)
          .add(['torso_verticality', 'depth_ratio'])
          .build();

    case 'cardio_action':
      return assembler
          .addAngles(
            FeatureGroups.anglesUpper + FeatureGroups.anglesLower,
            includeCosine: false,
          )
          .add(FeatureGroups.velocity3DHands)
          .add(FeatureGroups.velocity3DFeet)
          .add(['motion_magnitude'])
          .add(['hip_ankle_y_diff', 'torso_verticality'])
          .add(['torso_twist_ratio', 'angular_velocity_hips', 'facing_angle'])
          .build();

    case 'mat_precision':
      return assembler
          .addAngles(
            FeatureGroups.anglesUpper +
                FeatureGroups.anglesLower +
                FeatureGroups.anglesCore,
          )
          .add(FeatureGroups.visibilityFull)
          .add(FeatureGroups.spatialPosture)
          .add(FeatureGroups.spatialLegs)
          .add(FeatureGroups.spatialLevel)
          .add(['temporal_consistency', 'spine_curvature'])
          .build();

    case 'geometric_hybrid':
      return assembler
          .addAngles(
            FeatureGroups.anglesUpper +
                FeatureGroups.anglesLower +
                FeatureGroups.anglesCore,
            includeCosine: false,
          )
          .add(FeatureGroups.injuryKnees)
          .add(FeatureGroups.injuryElbows)
          .add(FeatureGroups.injurySpine)
          .add(FeatureGroups.velocityUpper)
          .add(FeatureGroups.velocityLower)
          .add(FeatureGroups.accelLower)
          .add(FeatureGroups.spatialPosture)
          .build();

    case 'full_body':
      return assembler
          .addAngles(
            FeatureGroups.anglesUpper +
                FeatureGroups.anglesLower +
                FeatureGroups.anglesCore,
          )
          .add(FeatureGroups.velocityUpper)
          .add(FeatureGroups.velocityLower)
          .add(FeatureGroups.velocity3DHands)
          .add(FeatureGroups.velocity3DFeet)
          .add(FeatureGroups.accelUpper)
          .add(FeatureGroups.accelLower)
          .add(FeatureGroups.injuryKnees)
          .add(FeatureGroups.injuryElbows)
          .add(FeatureGroups.injurySpine)
          .add(FeatureGroups.spatialPosture)
          .add(FeatureGroups.spatialLegs)
          .add(FeatureGroups.spatialLevel)
          .add(FeatureGroups.visibilityFull)
          .add(FeatureGroups.meta)
          .build();

    default:
      debugPrint(
        "Warning: Unknown feature set '$featureSetName'. Defaulting to 'strength_legs'.",
      );
      return getFeatureKeys('strength_legs');
  }
}

/// ExerciseModelOutput - Representation of the frame-by-frame model inference result
class ExerciseModelOutput {
  final List<double> phaseProbs;
  final double deviationScore;
  final List<double> currentFeatures;

  ExerciseModelOutput({
    required this.phaseProbs,
    required this.deviationScore,
    required this.currentFeatures,
  });

  factory ExerciseModelOutput.fromMap(Map<String, dynamic> map) {
    return ExerciseModelOutput(
      phaseProbs:
          (map['phase_probs'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      deviationScore: (map['deviation_score'] ?? 0.0).toDouble(),
      currentFeatures:
          (map['current_features'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }
}
