import 'dart:convert';
import '../../domain/entities/workout_curriculum.dart';
import 'workout_task_model.dart';

/// Data model for WorkoutCurriculum
/// Handles serialization/deserialization and mapping to domain entity
class WorkoutCurriculumModel {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final List<WorkoutTaskModel> workoutTasks;
  final DateTime createdAt;
  final int currentTaskIndex;
  final int currentSetIndex;

  const WorkoutCurriculumModel({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnail = '',
    required this.workoutTasks,
    required this.createdAt,
    this.currentTaskIndex = 0,
    this.currentSetIndex = 0,
  });

  /// Convert to domain entity
  WorkoutCurriculum toEntity() {
    return WorkoutCurriculum(
      id: id,
      title: title,
      description: description,
      thumbnail: thumbnail,
      workoutTasks: workoutTasks.map((model) => model.toEntity()).toList(),
      createdAt: createdAt,
      currentTaskIndex: currentTaskIndex,
      currentSetIndex: currentSetIndex,
    );
  }

  /// Create from domain entity
  factory WorkoutCurriculumModel.fromEntity(WorkoutCurriculum entity) {
    return WorkoutCurriculumModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      thumbnail: entity.thumbnail,
      workoutTasks: entity.workoutTasks
          .map((task) => WorkoutTaskModel.fromEntity(task))
          .toList(),
      createdAt: entity.createdAt,
      currentTaskIndex: entity.currentTaskIndex,
      currentSetIndex: entity.currentSetIndex,
    );
  }

  /// Create from JSON map
  factory WorkoutCurriculumModel.fromMap(Map<String, dynamic> map) {
    return WorkoutCurriculumModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      workoutTasks:
          (map['workoutTaskList'] as List<dynamic>?)
              ?.map((e) => WorkoutTaskModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      currentTaskIndex: map['currentTaskIndex'] ?? 0,
      currentSetIndex: map['currentSetIndex'] ?? 0,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'workoutTaskList': workoutTasks.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'currentTaskIndex': currentTaskIndex,
      'currentSetIndex': currentSetIndex,
    };
  }

  String toJson() => json.encode(toMap());

  factory WorkoutCurriculumModel.fromJson(String source) =>
      WorkoutCurriculumModel.fromMap(json.decode(source));
}
