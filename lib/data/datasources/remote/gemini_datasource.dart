import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../../models/workout_curriculum_model.dart';
import '../../models/workout_task_model.dart';
import '../../models/user_profile_model.dart';

/// Remote data source for Gemini AI operations
abstract class GeminiDataSource {
  Future<WorkoutCurriculumModel> generateCurriculum({
    required UserProfileModel profile,
    required String category,
    required List<WorkoutTaskModel> availableTasks,
  });
}

class GeminiDataSourceImpl implements GeminiDataSource {
  final GenerativeModel? _model;

  GeminiDataSourceImpl({GenerativeModel? model}) : _model = model;

  @override
  Future<WorkoutCurriculumModel> generateCurriculum({
    required UserProfileModel profile,
    required String category,
    required List<WorkoutTaskModel> availableTasks,
  }) async {
    try {
      // This is a simplified implementation
      // The actual implementation would use Gemini API to generate curriculum

      // For now, return a simple curriculum with available tasks
      final selectedTasks = availableTasks.take(3).toList();

      return WorkoutCurriculumModel(
        id: 'curriculum_${DateTime.now().millisecondsSinceEpoch}',
        title: 'AI Generated Workout',
        description: 'Personalized workout for ${profile.nickname}',
        workoutTasks: selectedTasks,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error generating curriculum with Gemini: $e');
      rethrow;
    }
  }
}
