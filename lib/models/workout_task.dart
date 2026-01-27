import 'dart:convert';

/// WorkoutTask - 개별 운동 정보
/// Firestore /workouts/{workout_id} 컬렉션에서 가져옴
class WorkoutTask {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final String readyPoseImageUrl;
  final String exampleVideoUrl;
  final String configureUrl;
  final String guideAudioUrl;
  final int reps;
  final int sets;
  final int timeoutSec;
  final String category; // squat, push, core, lunge
  final int difficulty; // 1-4

  // 실행 시 Gemini가 조정한 값
  int adjustedReps;
  int adjustedSets;

  WorkoutTask({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.readyPoseImageUrl,
    required this.exampleVideoUrl,
    required this.configureUrl,
    required this.guideAudioUrl,
    required this.reps,
    required this.sets,
    required this.timeoutSec,
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
      thumbnail: map['thumbnail'] ?? '',
      readyPoseImageUrl: map['readyPoseImageUrl'] ?? '',
      exampleVideoUrl: map['exampleVideoUrl'] ?? '',
      configureUrl: map['configureUrl'] ?? '',
      guideAudioUrl: map['guideAudioUrl'] ?? '',
      reps: map['reps'] ?? 10,
      sets: map['sets'] ?? 3,
      timeoutSec: map['timeout_sec'] ?? 60,
      category: map['category'] ?? 'squat',
      difficulty: map['difficulty'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'readyPoseImageUrl': readyPoseImageUrl,
      'exampleVideoUrl': exampleVideoUrl,
      'configureUrl': configureUrl,
      'guideAudioUrl': guideAudioUrl,
      'reps': reps,
      'sets': sets,
      'timeout_sec': timeoutSec,
      'category': category,
      'difficulty': difficulty,
    };
  }

  String toJson() => json.encode(toMap());

  factory WorkoutTask.fromJson(String source) =>
      WorkoutTask.fromMap(json.decode(source));

  /// Gemini 응답을 기반으로 조정된 reps/sets 적용
  void applyAdjustment({int? newReps, int? newSets}) {
    if (newReps != null) adjustedReps = newReps;
    if (newSets != null) adjustedSets = newSets;
  }

  /// 카테고리 한글 이름
  String get categoryDisplayName {
    switch (category) {
      case 'squat':
        return '하체';
      case 'push':
        return '상체';
      case 'core':
        return '코어';
      case 'lunge':
        return '런지';
      default:
        return category;
    }
  }

  /// 난이도 표시
  String get difficultyDisplayName {
    switch (difficulty) {
      case 1:
        return '입문';
      case 2:
        return '초급';
      case 3:
        return '중급';
      case 4:
        return '고급';
      default:
        return 'Level $difficulty';
    }
  }
}
