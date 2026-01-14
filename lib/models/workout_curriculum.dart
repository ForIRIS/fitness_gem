import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_task.dart';

/// WorkoutCurriculum - 오늘의 운동 커리큘럼
/// Gemini가 생성하고 로컬에 저장됨
class WorkoutCurriculum {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final List<WorkoutTask> workoutTaskList;
  final DateTime createdAt;

  // 진행 상태
  int currentTaskIndex;
  int currentSetIndex;

  WorkoutCurriculum({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.workoutTaskList,
    required this.createdAt,
    this.currentTaskIndex = 0,
    this.currentSetIndex = 0,
  });

  /// 총 예상 시간 (분)
  int get estimatedMinutes {
    int totalSets = 0;
    for (final task in workoutTaskList) {
      totalSets += task.adjustedSets;
    }
    // 세트당 약 1분 + 휴식 30초
    return (totalSets * 1.5).ceil();
  }

  /// 요약 텍스트 (예: "Air Squat 외 2종")
  String get summaryText {
    if (workoutTaskList.isEmpty) return '운동 없음';
    if (workoutTaskList.length == 1) return workoutTaskList.first.title;
    return '${workoutTaskList.first.title} 외 ${workoutTaskList.length - 1}종';
  }

  /// 현재 운동
  WorkoutTask? get currentTask {
    if (currentTaskIndex < workoutTaskList.length) {
      return workoutTaskList[currentTaskIndex];
    }
    return null;
  }

  /// 다음 운동
  WorkoutTask? get nextTask {
    if (currentTaskIndex + 1 < workoutTaskList.length) {
      return workoutTaskList[currentTaskIndex + 1];
    }
    return null;
  }

  /// 마지막 운동 여부
  bool get isLastTask => currentTaskIndex == workoutTaskList.length - 1;

  /// 완료 여부
  bool get isCompleted => currentTaskIndex >= workoutTaskList.length;

  /// 다음 세트로 이동
  void moveToNextSet() {
    final task = currentTask;
    if (task == null) return;

    currentSetIndex++;
    if (currentSetIndex >= task.adjustedSets) {
      // 다음 운동으로 이동
      currentTaskIndex++;
      currentSetIndex = 0;
    }
  }

  /// 진행 상태 리셋
  void reset() {
    currentTaskIndex = 0;
    currentSetIndex = 0;
  }

  factory WorkoutCurriculum.fromMap(Map<String, dynamic> map) {
    return WorkoutCurriculum(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      workoutTaskList:
          (map['workoutTaskList'] as List<dynamic>?)
              ?.map((e) => WorkoutTask.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      currentTaskIndex: map['currentTaskIndex'] ?? 0,
      currentSetIndex: map['currentSetIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'workoutTaskList': workoutTaskList.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'currentTaskIndex': currentTaskIndex,
      'currentSetIndex': currentSetIndex,
    };
  }

  String toJson() => json.encode(toMap());

  factory WorkoutCurriculum.fromJson(String source) =>
      WorkoutCurriculum.fromMap(json.decode(source));

  // SharedPreferences 저장/로드
  static const _key = 'today_curriculum';

  static Future<void> save(WorkoutCurriculum curriculum) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, curriculum.toJson());
  }

  static Future<WorkoutCurriculum?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      final curriculum = WorkoutCurriculum.fromJson(jsonString);
      // 오늘 생성된 커리큘럼만 반환
      if (_isSameDay(curriculum.createdAt, DateTime.now())) {
        return curriculum;
      }
    }
    return null;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
