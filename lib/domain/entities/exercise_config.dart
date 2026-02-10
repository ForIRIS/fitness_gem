import 'package:equatable/equatable.dart';
import '../../models/counting_mode.dart';
import '../../utils/adaptive_one_euro_filter.dart';

/// Domain Entity: ExerciseConfig
/// Pure business object representing exercise configuration for rep counting
class ExerciseConfig extends Equatable {
  final String id;
  final String? category;
  final Map<String, dynamic>? classLabels;
  final Map<String, dynamic>? medianStats;
  final Map<String, dynamic>? coachingCues;

  const ExerciseConfig({
    required this.id,
    this.category,
    this.classLabels,
    this.medianStats,
    this.coachingCues,
  });

  // Business logic methods

  /// Get counting mode from class labels
  CountingMode get countType =>
      CountingMode.fromString(classLabels?['countingMode']);

  /// Get count label from class labels
  String? get countLabel => classLabels?['countLabel'];

  /// Get trigger phase for duration mode (e.g. "PEAK")
  String? get triggerPhase => classLabels?['triggerPhase'];

  /// Get number of classes
  int? get numClasses => classLabels?['num_classes'];

  /// Get class phases map
  Map<String, dynamic>? get classPhases => classLabels?['class_phases'];

  /// Get window size (sequence length) from input_shape
  int get windowSize {
    final shape = classLabels?['input_shape'];
    if (shape is List && shape.length > 1) {
      // Shape is usually [1, SEQUENCE_LENGTH, LANDMARKS, 3]
      // or [1, SEQUENCE_LENGTH, ...]
      return shape[1] as int;
    }
    return 30; // Default
  }

  /// Get landmark dimensions (values per landmark) from input_shape
  /// e.g. 3 = [x, y, z], 4 = [x, y, z, visibility]
  int get landmarkDimensions {
    final shape = classLabels?['input_shape'];
    if (shape is List && shape.length > 3) {
      return shape[3] as int;
    }
    return 3; // Default to xyz only
  }

  /// Get smoothing profile for One Euro Filter
  OneEuroProfile get smoothingProfile {
    final explicitProfile = classLabels?['smoothingProfile']?.toString();
    if (explicitProfile != null) {
      return AdaptiveOneEuroFilter.profileFromString(explicitProfile);
    }
    // Fallback to category mapping
    return AdaptiveOneEuroFilter.profileFromCategory(category);
  }

  /// Get feature keys based on the feature set in classLabels
  List<String> get featureKeys {
    final featureSetName = classLabels?['feature_set'] as String?;
    if (featureSetName == null) return [];
    return _getFeatureKeys(featureSetName);
  }

  /// Helper to get feature keys (imported from model logic)
  List<String> _getFeatureKeys(String featureSetName) {
    // This will be imported from a shared utility
    // For now, return empty list - will be implemented with feature assembler
    return [];
  }

  @override
  List<Object?> get props => [
    id,
    category,
    classLabels,
    medianStats,
    coachingCues,
  ];

  ExerciseConfig copyWith({
    String? id,
    String? category,
    Map<String, dynamic>? classLabels,
    Map<String, dynamic>? medianStats,
    Map<String, dynamic>? coachingCues,
  }) {
    return ExerciseConfig(
      id: id ?? this.id,
      category: category ?? this.category,
      classLabels: classLabels ?? this.classLabels,
      medianStats: medianStats ?? this.medianStats,
      coachingCues: coachingCues ?? this.coachingCues,
    );
  }
}
