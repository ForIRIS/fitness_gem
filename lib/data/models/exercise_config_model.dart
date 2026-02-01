import 'dart:convert';
import '../../domain/entities/exercise_config.dart';

/// Data model for ExerciseConfig
/// Handles serialization/deserialization and mapping to domain entity
class ExerciseConfigModel {
  final String id;
  final String? category;
  final Map<String, dynamic>? classLabels;
  final Map<String, dynamic>? medianStats;
  final Map<String, dynamic>? coachingCues;

  const ExerciseConfigModel({
    required this.id,
    this.category,
    this.classLabels,
    this.medianStats,
    this.coachingCues,
  });

  /// Convert to domain entity
  ExerciseConfig toEntity() {
    return ExerciseConfig(
      id: id,
      category: category,
      classLabels: classLabels,
      medianStats: medianStats,
      coachingCues: coachingCues,
    );
  }

  /// Create from domain entity
  factory ExerciseConfigModel.fromEntity(ExerciseConfig entity) {
    return ExerciseConfigModel(
      id: entity.id,
      category: entity.category,
      classLabels: entity.classLabels,
      medianStats: entity.medianStats,
      coachingCues: entity.coachingCues,
    );
  }

  /// Create from JSON map
  factory ExerciseConfigModel.fromMap(
    Map<String, dynamic> map, {
    String? category,
  }) {
    return ExerciseConfigModel(
      id: map['id'] ?? '',
      category: category,
      classLabels: map['class_labels'],
      medianStats: map['base_model_stats'],
      coachingCues: map['base_model_cues'],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_labels': classLabels,
      'base_model_stats': medianStats,
      'base_model_cues': coachingCues,
    };
  }

  String toJson() => json.encode(toMap());

  factory ExerciseConfigModel.fromJson(String source) =>
      ExerciseConfigModel.fromMap(json.decode(source));
}
