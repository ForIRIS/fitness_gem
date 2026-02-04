import 'dart:convert';
import '../../domain/entities/workout_session.dart';

/// Model for serializing/deserializing WorkoutSession
class WorkoutSessionModel {
  final String id;
  final DateTime date;
  final int durationSeconds;
  final String curriculumId;
  final String curriculumTitle;
  final List<CompletedTaskModel> completedTasks;
  final double avgFormScore;

  WorkoutSessionModel({
    required this.id,
    required this.date,
    required this.durationSeconds,
    required this.curriculumId,
    required this.curriculumTitle,
    required this.completedTasks,
    this.avgFormScore = 0.0,
  });

  factory WorkoutSessionModel.fromEntity(WorkoutSession entity) {
    return WorkoutSessionModel(
      id: entity.id,
      date: entity.date,
      durationSeconds: entity.durationSeconds,
      curriculumId: entity.curriculumId,
      curriculumTitle: entity.curriculumTitle,
      completedTasks: entity.completedTasks
          .map((t) => CompletedTaskModel.fromEntity(t))
          .toList(),
      avgFormScore: entity.avgFormScore,
    );
  }

  WorkoutSession toEntity() {
    return WorkoutSession(
      id: id,
      date: date,
      durationSeconds: durationSeconds,
      curriculumId: curriculumId,
      curriculumTitle: curriculumTitle,
      completedTasks: completedTasks.map((t) => t.toEntity()).toList(),
      avgFormScore: avgFormScore,
    );
  }

  factory WorkoutSessionModel.fromMap(Map<String, dynamic> map) {
    return WorkoutSessionModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      durationSeconds: map['durationSeconds'] as int,
      curriculumId: map['curriculumId'] as String,
      curriculumTitle: map['curriculumTitle'] as String,
      completedTasks: (map['completedTasks'] as List<dynamic>)
          .map((t) => CompletedTaskModel.fromMap(t as Map<String, dynamic>))
          .toList(),
      avgFormScore: (map['avgFormScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'curriculumId': curriculumId,
      'curriculumTitle': curriculumTitle,
      'completedTasks': completedTasks.map((t) => t.toMap()).toList(),
      'avgFormScore': avgFormScore,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory WorkoutSessionModel.fromJson(String json) {
    return WorkoutSessionModel.fromMap(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }
}

/// Model for CompletedTask serialization
class CompletedTaskModel {
  final String taskId;
  final String taskTitle;
  final String category;
  final int reps;
  final int sets;
  final double weight;
  final double formScore;

  CompletedTaskModel({
    required this.taskId,
    required this.taskTitle,
    required this.category,
    required this.reps,
    required this.sets,
    this.weight = 0.0,
    this.formScore = 0.0,
  });

  factory CompletedTaskModel.fromEntity(CompletedTask entity) {
    return CompletedTaskModel(
      taskId: entity.taskId,
      taskTitle: entity.taskTitle,
      category: entity.category,
      reps: entity.reps,
      sets: entity.sets,
      weight: entity.weight,
      formScore: entity.formScore,
    );
  }

  CompletedTask toEntity() {
    return CompletedTask(
      taskId: taskId,
      taskTitle: taskTitle,
      category: category,
      reps: reps,
      sets: sets,
      weight: weight,
      formScore: formScore,
    );
  }

  factory CompletedTaskModel.fromMap(Map<String, dynamic> map) {
    return CompletedTaskModel(
      taskId: map['taskId'] as String,
      taskTitle: map['taskTitle'] as String,
      category: map['category'] as String,
      reps: map['reps'] as int,
      sets: map['sets'] as int,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      formScore: (map['formScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'category': category,
      'reps': reps,
      'sets': sets,
      'weight': weight,
      'formScore': formScore,
    };
  }
}
