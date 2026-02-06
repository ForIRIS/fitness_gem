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
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      advice: map['advice']?.toString() ?? '',
      thumbnail: map['thumbnail']?.toString() ?? '',
      readyPoseImageUrl:
          (map['ready_pose_image_url'] ?? map['readyPoseImageUrl'])
              ?.toString() ??
          '',
      exampleVideoUrl:
          (map['example_video_url'] ?? map['exampleVideoUrl'])?.toString() ??
          '',
      configureUrl:
          (map['configure_url'] ?? map['configureUrl'])?.toString() ?? '',
      guideAudioUrl:
          (map['guide_audio_url'] ?? map['guideAudioUrl'])?.toString() ?? '',
      coremlUrl: (map['coreml_url'] ?? map['coremlUrl'])?.toString() ?? '',
      onnxUrl: (map['onnx_url'] ?? map['onnxUrl'])?.toString() ?? '',
      reps: int.tryParse(map['reps']?.toString() ?? '10') ?? 10,
      sets: int.tryParse(map['sets']?.toString() ?? '3') ?? 3,
      timeoutSec:
          int.tryParse(
            (map['timeout_sec'] ?? map['timeoutSec'])?.toString() ?? '60',
          ) ??
          60,
      durationSec: int.tryParse(
        (map['duration_sec'] ?? map['durationSec'])?.toString() ?? '',
      ),
      isCountable:
          map['is_countable'] ??
          map['isCountable'] ??
          (map['isCountable'] == null),
      category: map['category']?.toString() ?? 'squat',
      difficulty: int.tryParse(map['difficulty']?.toString() ?? '1') ?? 1,
      adjustedReps: int.tryParse(
        (map['adjusted_reps'] ?? map['adjustedReps'])?.toString() ?? '',
      ),
      adjustedSets: int.tryParse(
        (map['adjusted_sets'] ?? map['adjustedSets'])?.toString() ?? '',
      ),
    );
  }

  /// copyWith method
  WorkoutTaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? advice,
    String? thumbnail,
    String? readyPoseImageUrl,
    String? exampleVideoUrl,
    String? configureUrl,
    String? guideAudioUrl,
    String? coremlUrl,
    String? onnxUrl,
    int? reps,
    int? sets,
    int? timeoutSec,
    int? durationSec,
    bool? isCountable,
    String? category,
    int? difficulty,
    int? adjustedReps,
    int? adjustedSets,
  }) {
    return WorkoutTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      advice: advice ?? this.advice,
      thumbnail: thumbnail ?? this.thumbnail,
      readyPoseImageUrl: readyPoseImageUrl ?? this.readyPoseImageUrl,
      exampleVideoUrl: exampleVideoUrl ?? this.exampleVideoUrl,
      configureUrl: configureUrl ?? this.configureUrl,
      guideAudioUrl: guideAudioUrl ?? this.guideAudioUrl,
      coremlUrl: coremlUrl ?? this.coremlUrl,
      onnxUrl: onnxUrl ?? this.onnxUrl,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      timeoutSec: timeoutSec ?? this.timeoutSec,
      durationSec: durationSec ?? this.durationSec,
      isCountable: isCountable ?? this.isCountable,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      adjustedReps: adjustedReps ?? this.adjustedReps,
      adjustedSets: adjustedSets ?? this.adjustedSets,
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
