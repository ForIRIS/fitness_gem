import 'dart:convert';
import '../../domain/entities/workout_task.dart';

/// Data model for WorkoutTask
/// Handles serialization/deserialization and mapping to domain entity
class WorkoutTaskModel {
  final String id;
  final String title;
  final String description;
  final String advice;
  final String thumbnail;
  final String readyPoseImageUrl;
  final String exampleVideoUrl;
  final String configureUrl;
  final String guideAudioUrl;
  final String coremlUrl;
  final String onnxUrl;
  final int reps;
  final int sets;
  final int timeoutSec;
  final int? durationSec;
  final bool isCountable;
  final String category;
  final int difficulty;
  final int? adjustedReps;
  final int? adjustedSets;

  const WorkoutTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.advice,
    this.thumbnail = '',
    this.readyPoseImageUrl = '',
    this.exampleVideoUrl = '',
    this.configureUrl = '',
    this.guideAudioUrl = '',
    this.coremlUrl = '',
    this.onnxUrl = '',
    required this.reps,
    required this.sets,
    required this.timeoutSec,
    this.durationSec,
    this.isCountable = true,
    required this.category,
    required this.difficulty,
    this.adjustedReps,
    this.adjustedSets,
  });

  /// Convert to domain entity
  WorkoutTask toEntity() {
    return WorkoutTask(
      id: id,
      title: title,
      description: description,
      advice: advice,
      category: category,
      difficulty: difficulty,
      reps: reps,
      sets: sets,
      timeoutSec: timeoutSec,
      durationSec: durationSec,
      isCountable: isCountable,
      thumbnail: thumbnail,
      readyPoseImageUrl: readyPoseImageUrl,
      exampleVideoUrl: exampleVideoUrl,
      configureUrl: configureUrl,
      guideAudioUrl: guideAudioUrl,
      coremlUrl: coremlUrl,
      onnxUrl: onnxUrl,
      adjustedReps: adjustedReps,
      adjustedSets: adjustedSets,
    );
  }

  /// Create from domain entity
  factory WorkoutTaskModel.fromEntity(WorkoutTask entity) {
    return WorkoutTaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      advice: entity.advice,
      category: entity.category,
      difficulty: entity.difficulty,
      reps: entity.reps,
      sets: entity.sets,
      timeoutSec: entity.timeoutSec,
      durationSec: entity.durationSec,
      isCountable: entity.isCountable,
      thumbnail: entity.thumbnail,
      readyPoseImageUrl: entity.readyPoseImageUrl,
      exampleVideoUrl: entity.exampleVideoUrl,
      configureUrl: entity.configureUrl,
      guideAudioUrl: entity.guideAudioUrl,
      coremlUrl: entity.coremlUrl,
      onnxUrl: entity.onnxUrl,
      adjustedReps: entity.adjustedReps,
      adjustedSets: entity.adjustedSets,
    );
  }

  /// Create from JSON map
  factory WorkoutTaskModel.fromMap(Map<String, dynamic> map) {
    return WorkoutTaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      advice: map['advice'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      readyPoseImageUrl: map['readyPoseImageUrl'] ?? '',
      exampleVideoUrl: map['exampleVideoUrl'] ?? '',
      configureUrl: map['configureUrl'] ?? '',
      guideAudioUrl: map['guideAudioUrl'] ?? '',
      coremlUrl: map['coremlUrl'] ?? '',
      onnxUrl: map['onnxUrl'] ?? '',
      reps: map['reps'] ?? 10,
      sets: map['sets'] ?? 3,
      timeoutSec: map['timeout_sec'] ?? 60,
      durationSec: map['duration_sec'],
      isCountable: map['is_countable'] ?? true,
      category: map['category'] ?? 'squat',
      difficulty: map['difficulty'] ?? 1,
      adjustedReps: map['adjustedReps'],
      adjustedSets: map['adjustedSets'],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'advice': advice,
      'thumbnail': thumbnail,
      'readyPoseImageUrl': readyPoseImageUrl,
      'exampleVideoUrl': exampleVideoUrl,
      'configureUrl': configureUrl,
      'guideAudioUrl': guideAudioUrl,
      'coremlUrl': coremlUrl,
      'onnxUrl': onnxUrl,
      'reps': reps,
      'sets': sets,
      'timeout_sec': timeoutSec,
      if (durationSec != null) 'duration_sec': durationSec,
      'is_countable': isCountable,
      'category': category,
      'difficulty': difficulty,
      if (adjustedReps != null) 'adjustedReps': adjustedReps,
      if (adjustedSets != null) 'adjustedSets': adjustedSets,
    };
  }

  String toJson() => json.encode(toMap());

  factory WorkoutTaskModel.fromJson(String source) =>
      WorkoutTaskModel.fromMap(json.decode(source));
}
