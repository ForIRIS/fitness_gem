import 'dart:convert';

/// WorkoutTask - Individual workout info
/// Fetched from Firestore /workouts/{workout_id} collection
class WorkoutTask {
  final String id;
  final String title;
  final String description;
  final String advice;
  String thumbnail;
  String readyPoseImageUrl;
  String exampleVideoUrl;
  String configureUrl;
  String guideAudioUrl;
  final int reps;
  final int sets;
  final int timeoutSec;
  final int durationSec; // For non-countable exercises (e.g., planks)
  final bool isCountable; // true = rep-based, false = duration-based
  final String category; // squat, push, core, lunge
  final int difficulty; // 1-4

  // Values adjusted by Gemini during execution
  int adjustedReps;
  int adjustedSets;

  WorkoutTask({
    required this.id,
    required this.title,
    required this.description,
    required this.advice,
    required this.thumbnail,
    required this.readyPoseImageUrl,
    required this.exampleVideoUrl,
    required this.configureUrl,
    required this.guideAudioUrl,
    required this.reps,
    required this.sets,
    required this.timeoutSec,
    this.durationSec = 0,
    this.isCountable = true,
    required this.category,
    required this.difficulty,
    int? adjustedReps,
    int? adjustedSets,
  }) : adjustedReps = adjustedReps ?? reps,
       adjustedSets = adjustedSets ?? sets;

  factory WorkoutTask.fromMap(Map<String, dynamic> map) {
    return WorkoutTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      advice: map['advice'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      readyPoseImageUrl: map['readyPoseImageUrl'] ?? '',
      exampleVideoUrl: map['exampleVideoUrl'] ?? '',
      configureUrl: map['configureUrl'] ?? '',
      guideAudioUrl: map['guideAudioUrl'] ?? '',
      reps: map['reps'] ?? 10,
      sets: map['sets'] ?? 3,
      timeoutSec: map['timeout_sec'] ?? 60,
      durationSec: map['duration_sec'] ?? 0,
      isCountable: map['is_countable'] ?? true,
      category: map['category'] ?? 'squat',
      difficulty: map['difficulty'] ?? 1,
    );
  }

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
      'reps': reps,
      'sets': sets,
      'timeout_sec': timeoutSec,
      'duration_sec': durationSec,
      'is_countable': isCountable,
      'category': category,
      'difficulty': difficulty,
    };
  }

  String toJson() => json.encode(toMap());

  factory WorkoutTask.fromJson(String source) =>
      WorkoutTask.fromMap(json.decode(source));

  /// Apply reps/sets adjustment based on Gemini response
  void applyAdjustment({int? newReps, int? newSets}) {
    if (newReps != null) adjustedReps = newReps;
    if (newSets != null) adjustedSets = newSets;
  }

  /// Check if media info is missing
  bool get hasMediaInfo =>
      thumbnail.isNotEmpty &&
      readyPoseImageUrl.isNotEmpty &&
      exampleVideoUrl.isNotEmpty;

  /// Update media info from Cloud Functions or other sources
  void updateMediaInfo({
    String? newThumbnail,
    String? newReadyPoseImageUrl,
    String? newExampleVideoUrl,
    String? newGuideAudioUrl,
  }) {
    if (newThumbnail != null && newThumbnail.isNotEmpty) {
      thumbnail = newThumbnail;
    }
    if (newReadyPoseImageUrl != null && newReadyPoseImageUrl.isNotEmpty) {
      readyPoseImageUrl = newReadyPoseImageUrl;
    }
    if (newExampleVideoUrl != null && newExampleVideoUrl.isNotEmpty) {
      exampleVideoUrl = newExampleVideoUrl;
    }
    if (newGuideAudioUrl != null && newGuideAudioUrl.isNotEmpty) {
      guideAudioUrl = newGuideAudioUrl;
    }
  }

  /// Category display name
  String get categoryDisplayName {
    switch (category) {
      case 'squat':
        return 'Squat';
      case 'push':
        return 'Push';
      case 'core':
        return 'Core';
      case 'lunge':
        return 'Lunge';
      default:
        return category;
    }
  }

  /// Difficulty display
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
        return 'Level $difficulty';
    }
  }
}
