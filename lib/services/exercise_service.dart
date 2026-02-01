import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_config.dart';
import '../domain/entities/workout_task.dart';
import '../data/models/workout_task_model.dart';
import 'cache_service.dart';
import 'firebase_service.dart';

class ExerciseService {
  // TODO: Replace with your actual Firebase Cloud Function URL
  static const String _functionsUrl =
      'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/getExerciseConfig';

  static const String _localWorkoutsKey = 'local_workouts';
  final FirebaseService _firebaseService = FirebaseService();
  final CacheService _cacheService = CacheService();

  /// Get Exercise Configuration
  /// Prioritizes cached file if available -> then Remote -> then Sample/Mock
  Future<ExerciseConfig?> getExerciseConfig(
    WorkoutTask task, {
    bool useMock = false,
  }) async {
    // If test flag is set or ID matches internal sample ID
    if (useMock || task.id == 'sample_back_lunge') {
      return _getSampleConfig(task.id);
    }

    try {
      // 1. Check Cache
      if (task.configureUrl.isNotEmpty) {
        final cachedPath = await _cacheService.getCachedPath(task.configureUrl);
        if (cachedPath != null) {
          final file = File(cachedPath);
          if (await file.exists()) {
            final content = await file.readAsString();
            final data = json.decode(content);
            debugPrint('Loaded config from cache: ${task.configureUrl}');
            return ExerciseConfig.fromMap(data, category: task.category);
          }
        }
      }

      // 2. Fetch from URL (Cloud Function / ConfigureUrl)
      final url = task.configureUrl.isNotEmpty
          ? task.configureUrl
          : '$_functionsUrl?id=${task.id}';

      if (url.startsWith('http')) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return ExerciseConfig.fromMap(data, category: task.category);
        }
      }

      // 3. Fallback to Sample/Mock if no URL or fetch failed (for MVP)
      debugPrint('Fetching config failed or empty URL. Using Sample/Mock.');
      return _getSampleConfig(task.id);
    } catch (e) {
      debugPrint('Error fetching exercise config: $e');
      return _getSampleConfig(task.id);
    }
  }

  Future<WorkoutTask> getSampleWorkoutTask() async {
    return WorkoutTask(
      id: '31c7abde-ede2-4647-b366-4cfb9bf55bbe',
      title: 'Back Lunge',
      category: 'lunge',
      description: 'Train your legs with back lunges using the sample model.',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      difficulty: 2,
      isCountable: true,
      advice: 'Step back and keep your front knee at 90 degrees.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
    );
  }

  /// Get Workout List (Repository Pattern)
  /// Merges: Built-in + Local + Remote
  Future<List<WorkoutTask>> getAvailableWorkouts({
    bool forceRefresh = false,
  }) async {
    final workoutsMap = <String, WorkoutTask>{};

    // Add Sample Workout for Testing
    final sampleWorkout = WorkoutTask(
      id: '31c7abde-ede2-4647-b366-4cfb9bf55bbe',
      title: 'Back Lunge',
      category: 'lunge',
      description: 'Train your legs with back lunges using the sample model.',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      difficulty: 2,
      isCountable: true,
      advice: 'Step back and keep your front knee at 90 degrees.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
    );
    workoutsMap[sampleWorkout.id] = sampleWorkout;

    // ... rest of the method

    // 1. Fetch Remote (Firebase) - This includes Built-in fallback if offline/empty
    // We assume FirebaseService returns the "Master List"
    try {
      final remoteWorkouts = await _firebaseService.fetchWorkoutAllList();
      for (final workout in remoteWorkouts) {
        workoutsMap[workout.id] = workout;
      }
    } catch (e) {
      debugPrint('Error fetching remote workouts: $e');
    }

    // 2. Load Local Overrides/Additions
    try {
      final localWorkouts = await _getLocalWorkouts();
      for (final workout in localWorkouts) {
        workoutsMap[workout.id] = workout;
      }
    } catch (e) {
      debugPrint('Error loading local workouts: $e');
    }

    return workoutsMap.values.toList();
  }

  /// Load workouts saved locally
  Future<List<WorkoutTask>> _getLocalWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_localWorkoutsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((e) => WorkoutTaskModel.fromMap(e).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error parsing local workouts: $e');
      return [];
    }
  }

  /// Save workout metadata to local storage
  Future<void> saveWorkoutToLocal(WorkoutTask task) async {
    final currentList = await _getLocalWorkouts();
    // Remove existing if any (update)
    currentList.removeWhere((t) => t.id == task.id);
    currentList.add(task);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = currentList
        .map((t) => WorkoutTaskModel.fromEntity(t).toMap())
        .toList();
    await prefs.setString(_localWorkoutsKey, json.encode(jsonList));
  }

  /// Get Sample Configuration from assets
  Future<ExerciseConfig?> _getSampleConfig(String exerciseId) async {
    try {
      // Base path for sample assets
      const basePath = 'assets/models/31c7abde-ede2-4647-b366-4cfb9bf55bbe';

      // Load and parse JSON files
      final classLabelsStr = await rootBundle.loadString(
        '$basePath/class_labels.json',
      );
      final statsStr = await rootBundle.loadString(
        '$basePath/base_model_stats.json',
      );
      final cuesStr = await rootBundle.loadString(
        '$basePath/base_model_cues.json',
      );

      final Map<String, dynamic> configMap = {
        'id': exerciseId,
        'class_labels': json.decode(classLabelsStr),
        'median_stats': json.decode(statsStr),
        'coaching_cues': json.decode(cuesStr),
      };

      debugPrint('Loaded sample config for: $exerciseId');
      return ExerciseConfig.fromMap(configMap, category: exerciseId);
    } catch (e) {
      debugPrint('Error loading sample config: $e');
      return ExerciseConfig.defaultSquat();
    }
  }
}
