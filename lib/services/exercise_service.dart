import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_config.dart';
import '../models/workout_task.dart';
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
  /// Prioritizes cached file if available -> then Remote -> then Mock
  Future<ExerciseConfig?> getExerciseConfig(
    WorkoutTask task, {
    bool useMock = false,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockConfig(task.id);
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
            return ExerciseConfig.fromMap(data);
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
          return ExerciseConfig.fromMap(data);
        }
      }

      // 3. Fallback to Mock if no URL or fetch failed (for MVP)
      debugPrint('Fetching config failed or empty URL. Using Mock.');
      return _getMockConfig(task.id);
    } catch (e) {
      debugPrint('Error fetching exercise config: $e');
      return _getMockConfig(task.id);
    }
  }

  /// Get Workout List (Repository Pattern)
  /// Merges: Built-in + Local + Remote
  Future<List<WorkoutTask>> getAvailableWorkouts({
    bool forceRefresh = false,
  }) async {
    final workoutsMap = <String, WorkoutTask>{};

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
        // Local data might overwrite remote if we want (e.g., custom edits),
        // or just add new ones. For now, let's treat Local as 'offline cache' mostly,
        // but if it's a new ID, we add it. If same ID, maybe Local is fresher?
        // Let's assume Remote is source of truth, but Local keeps downloaded status logic if we add it.
        // Simple merge: ID based.
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
      return jsonList.map((e) => WorkoutTask.fromMap(e)).toList();
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
    final jsonList = currentList.map((t) => t.toMap()).toList();
    await prefs.setString(_localWorkoutsKey, json.encode(jsonList));
  }

  ExerciseConfig _getMockConfig(String exerciseId) {
    // Branch by ID or Name
    final id = exerciseId.toLowerCase();

    // Common Mock Data matching User Request structure
    final mockClassLabels = {
      "classes": [
        "1_Ready",
        "2_Right_Down",
        "3_Right_Peak",
        "4_Right_Up",
        "5_Left_Down",
        "6_Left_Peak",
        "7_Left_Up",
        "8_Right_up",
      ],
      "num_classes": 8,
      "input_shape": [1, 30, 33, 3],
      "input_name": "landmarks",
      "feature_set": "strength_legs",
      "runtime": "onnxruntime-mobile",
      "opset_version": 18,
    };

    final mockMedianStats = {
      "feature_set": "strength_legs",
      "labels": {
        "1_Ready": {"cosine_hip_abduction": 0.8526791930198669},
      },
    };

    final mockCoachingCues = {
      "1_Ready": {
        "hip_knee_ankle_l": {
          "movement": "Keep your chest upright and core tight the movement.",
        },
      },
    };

    if (id.contains('squat')) {
      return ExerciseConfig.defaultSquat().copyWith(
        classLabels: mockClassLabels,
        medianStats: mockMedianStats,
        coachingCues: mockCoachingCues,
      );
    }
    if (id.contains('push')) {
      return ExerciseConfig.defaultPushup();
    }
    if (id.contains('lunge')) {
      return ExerciseConfig.defaultLunge();
    }
    if (id.contains('core')) {
      return ExerciseConfig.defaultPlank();
    }

    return ExerciseConfig.defaultSquat();
  }
}
