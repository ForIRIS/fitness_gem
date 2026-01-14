import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/exercise_config.dart';
import '../models/workout_task.dart';

class ExerciseService {
  // TODO: Replace with your actual Firebase Cloud Function URL
  static const String _functionsUrl =
      'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/getExerciseConfig';

  /// 운동 설정 가져오기
  /// [useMock]이 true면 로컬 더미 데이터 반환
  Future<ExerciseConfig?> getExerciseConfig(
    String exerciseId, {
    bool useMock = true,
  }) async {
    if (useMock) {
      // Mock data logic
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network
      return _getMockConfig(exerciseId);
    }

    try {
      final response = await http.get(
        Uri.parse('$_functionsUrl?id=$exerciseId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ExerciseConfig.fromMap(data);
      } else {
        debugPrint('Failed to load exercise config: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching exercise config: $e');
      return null;
    }
  }

  /// 운동 목록 가져오기 (Curriculum용)
  Future<List<WorkoutTask>> getAvailableWorkouts({bool useMock = true}) async {
    if (useMock) {
      return _getMockWorkouts();
    }
    // TODO: Implement Cloud Function call
    return [];
  }

  ExerciseConfig _getMockConfig(String exerciseId) {
    // ID나 이름에 따라 분기
    final id = exerciseId.toLowerCase();
    if (id.contains('squat')) return ExerciseConfig.defaultSquat();
    if (id.contains('push')) return ExerciseConfig.defaultPushup();
    if (id.contains('lunge')) return ExerciseConfig.defaultLunge();

    return ExerciseConfig.defaultSquat();
  }

  List<WorkoutTask> _getMockWorkouts() {
    return [
      WorkoutTask(
        id: 'squat_01',
        title: 'Air Squat',
        description: 'Basic lower body exercise',
        category: 'Squat',
        difficulty: 1,
        reps: 15,
        sets: 3,
        timeoutSec: 60,
        thumbnail: 'https://placehold.co/100x100.png',
        readyPoseImageUrl: 'https://placehold.co/200x300.png',
        exampleVideoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        configureUrl: '',
        guideAudioUrl: '',
      ),
      WorkoutTask(
        id: 'pushup_01',
        title: 'Push-up',
        description: 'Upper body strength',
        category: 'Push',
        difficulty: 2,
        reps: 10,
        sets: 3,
        timeoutSec: 60,
        thumbnail: 'https://placehold.co/100x100.png',
        readyPoseImageUrl: 'https://placehold.co/200x300.png',
        exampleVideoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        configureUrl: '',
        guideAudioUrl: '',
      ),
    ];
  }
}
