import 'package:equatable/equatable.dart';

/// Domain Entity: WorkoutTask
/// Pure business object representing a single workout exercise
class WorkoutTask extends Equatable {
  final String id;
  final String title;
  final String description;
  final String advice;
  final String category;
  final int difficulty;
  final int reps;
  final int sets;
  final int timeoutSec;
  final int? durationSec;
  final bool isCountable;

  // Resource URLs
  final String thumbnail;
  final String readyPoseImageUrl;
  final String exampleVideoUrl;
  final String configureUrl;
  final String guideAudioUrl;
  final String coremlUrl;
  final String onnxUrl;

  // Adjusted values (immutable - use copyWith to modify)
  final int adjustedReps;
  final int adjustedSets;
  final int? adjustedDurationSec;

  const WorkoutTask({
    required this.id,
    required this.title,
    required this.description,
    required this.advice,
    required this.category,
    required this.difficulty,
    required this.reps,
    required this.sets,
    required this.timeoutSec,
    this.durationSec,
    required this.isCountable,
    this.thumbnail = '',
    this.readyPoseImageUrl = '',
    this.exampleVideoUrl = '',
    this.configureUrl = '',
    this.guideAudioUrl = '',
    this.coremlUrl = '',
    this.onnxUrl = '',
    int? adjustedReps,
    int? adjustedSets,
    this.adjustedDurationSec,
  }) : adjustedReps = adjustedReps ?? reps,
       adjustedSets = adjustedSets ?? sets;

  // Business logic
  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'squat':
        return 'Lower Body';
      case 'push':
        return 'Upper Body';
      case 'core':
        return 'Core';
      case 'lunge':
        return 'Legs';
      default:
        return category;
    }
  }

  String get difficultyDisplayName {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      case 4:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  /// Check if media info (URLs) are available
  bool get hasMediaInfo {
    return exampleVideoUrl.isNotEmpty &&
        configureUrl.isNotEmpty &&
        guideAudioUrl.isNotEmpty;
  }

  /// Apply adjustment to reps/sets/duration (returns new instance)
  WorkoutTask withAdjustment({int? reps, int? sets, int? durationSec}) {
    return copyWith(
      adjustedReps: reps,
      adjustedSets: sets,
      adjustedDurationSec: durationSec,
    );
  }

  /// Update media info (returns new instance)
  WorkoutTask withMediaInfo({
    String? thumbnail,
    String? readyPoseImageUrl,
    String? exampleVideoUrl,
    String? configureUrl,
    String? guideAudioUrl,
    String? coremlUrl,
    String? onnxUrl,
  }) {
    return copyWith(
      thumbnail: thumbnail,
      readyPoseImageUrl: readyPoseImageUrl,
      exampleVideoUrl: exampleVideoUrl,
      configureUrl: configureUrl,
      guideAudioUrl: guideAudioUrl,
      coremlUrl: coremlUrl,
      onnxUrl: onnxUrl,
    );
  }

  /// Copy with method for creating modified instances
  WorkoutTask copyWith({
    String? id,
    String? title,
    String? description,
    String? advice,
    String? category,
    int? difficulty,
    int? reps,
    int? sets,
    int? timeoutSec,
    int? durationSec,
    bool? isCountable,
    String? thumbnail,
    String? readyPoseImageUrl,
    String? exampleVideoUrl,
    String? configureUrl,
    String? guideAudioUrl,
    String? coremlUrl,
    String? onnxUrl,
    int? adjustedReps,
    int? adjustedSets,
    int? adjustedDurationSec,
  }) {
    return WorkoutTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      advice: advice ?? this.advice,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      timeoutSec: timeoutSec ?? this.timeoutSec,
      durationSec: durationSec ?? this.durationSec,
      isCountable: isCountable ?? this.isCountable,
      thumbnail: thumbnail ?? this.thumbnail,
      readyPoseImageUrl: readyPoseImageUrl ?? this.readyPoseImageUrl,
      exampleVideoUrl: exampleVideoUrl ?? this.exampleVideoUrl,
      configureUrl: configureUrl ?? this.configureUrl,
      guideAudioUrl: guideAudioUrl ?? this.guideAudioUrl,
      coremlUrl: coremlUrl ?? this.coremlUrl,
      onnxUrl: onnxUrl ?? this.onnxUrl,
      adjustedReps: adjustedReps ?? this.adjustedReps,
      adjustedSets: adjustedSets ?? this.adjustedSets,
      adjustedDurationSec: adjustedDurationSec ?? this.adjustedDurationSec,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    advice,
    category,
    difficulty,
    reps,
    sets,
    timeoutSec,
    durationSec,
    isCountable,
    thumbnail,
    readyPoseImageUrl,
    exampleVideoUrl,
    configureUrl,
    guideAudioUrl,
    coremlUrl,
    onnxUrl,
    adjustedReps,
    adjustedSets,
    adjustedDurationSec,
  ];
}
