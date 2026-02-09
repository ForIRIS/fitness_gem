import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/exercise_config.dart';
import '../../../domain/entities/workout_task.dart';
import '../../../services/cache_service.dart';
import '../models/exercise_config_model.dart';
import '../models/workout_task_model.dart';
import '../../../core/constants/mock_data.dart';
import '../../../utils/asset_utils.dart';
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
    // Load from assets bundle
    try {
      final bundlePath = 'assets/bundles/$taskId.zip';
      final unzippedPath = await AssetUtils.unzipAssetToTemp(
        bundlePath,
        taskId,
      );

      final classLabelsFile = File('$unzippedPath/class_labels.json');
      final statsFile = File('$unzippedPath/base_model_stats.json');
      final cuesFile = File('$unzippedPath/base_model_cues.json');

      if (!await classLabelsFile.exists()) {
        return const ExerciseConfig(id: 'default');
      }

      final classLabelsStr = await classLabelsFile.readAsString();
      final statsStr = await statsFile.readAsString();
      final cuesStr = await cuesFile.readAsString();

      final data = {
        'id': taskId,
        'class_labels': json.decode(classLabelsStr),
        'median_stats': json.decode(statsStr),
        'coaching_cues': json.decode(cuesStr),
      };

      final model = ExerciseConfigModel.fromMap(data);
      return model.toEntity();
    } catch (e) {
      // Return default config
      return const ExerciseConfig(id: 'default');
    }
  }

  @override
  Future<WorkoutTask> getSampleWorkoutTask() async {
    // Return the first available mock task or a specific one
    if (mockWorkoutTasks.isNotEmpty) {
      return mockWorkoutTasks.first.toEntity();
    }
    throw Exception('No sample workout available');
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
}
