import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/exercise_config.dart';
import '../../../domain/entities/workout_task.dart';
import '../../../services/cache_service.dart';
import '../models/exercise_config_model.dart';
import '../models/workout_task_model.dart';
import 'exercise_local_datasource.dart';

class ExerciseLocalDataSourceImpl implements ExerciseLocalDataSource {
  final CacheService _cacheService;
  static const String _localWorkoutsKey = 'local_workouts';

  ExerciseLocalDataSourceImpl({CacheService? cacheService})
    : _cacheService = cacheService ?? CacheService();

  @override
  Future<ExerciseConfig?> getCachedExerciseConfig(String url) async {
    final cachedPath = await _cacheService.getCachedPath(url);
    if (cachedPath != null) {
      final file = File(cachedPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        final model = ExerciseConfigModel.fromMap(data);
        return model.toEntity();
      }
    }
    return null;
  }

  @override
  Future<void> cacheExerciseConfig(String url, ExerciseConfig config) async {
    // Cache service would handle the actual caching
    // This is a placeholder for now
  }

  @override
  Future<ExerciseConfig> getSampleExerciseConfig(String taskId) async {
    // Load from assets or return default config
    try {
      final jsonString = await rootBundle.loadString(
        'assets/configs/$taskId.json',
      );
      final data = json.decode(jsonString);
      final model = ExerciseConfigModel.fromMap(data);
      return model.toEntity();
    } catch (e) {
      // Return default config
      return const ExerciseConfig(id: 'default');
    }
  }

  @override
  Future<List<WorkoutTask>> getLocalWorkoutTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_localWorkoutsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((json) => WorkoutTaskModel.fromMap(json).toEntity())
        .toList();
  }

  @override
  Future<void> saveWorkoutTask(WorkoutTask task) async {
    final prefs = await SharedPreferences.getInstance();
    final existingTasks = await getLocalWorkoutTasks();

    // Remove existing task with same ID if present
    existingTasks.removeWhere((t) => t.id == task.id);
    existingTasks.add(task);

    final models = existingTasks
        .map((t) => WorkoutTaskModel.fromEntity(t))
        .toList();
    final jsonString = json.encode(models.map((m) => m.toMap()).toList());
    await prefs.setString(_localWorkoutsKey, jsonString);
  }

  @override
  Future<void> deleteWorkoutTask(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingTasks = await getLocalWorkoutTasks();
    existingTasks.removeWhere((t) => t.id == taskId);

    final models = existingTasks
        .map((t) => WorkoutTaskModel.fromEntity(t))
        .toList();
    final jsonString = json.encode(models.map((m) => m.toMap()).toList());
    await prefs.setString(_localWorkoutsKey, jsonString);
  }

  @override
  Future<WorkoutTask> getSampleWorkoutTask() async {
    return const WorkoutTask(
      id: '31c7abde-ede2-4647-b366-4cfb9bf55bbe',
      title: 'Back Lunge',
      category: 'lunge',
      description:
          'A unilateral movement that focuses on the quadriceps and glutes while minimizing stress on the front knee. Improves lower body stability and functional strength.',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      difficulty: 2,
      isCountable: true,
      advice:
          'Step back precisely and drop your back knee toward the floor. Maintain an upright torso and drive through your front heel to return to center.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
    );
  }
}
