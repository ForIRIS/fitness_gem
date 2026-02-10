import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../firebase_options.dart';
import '../domain/entities/workout_task.dart';
import '../domain/entities/workout_curriculum.dart';
import '../data/models/workout_task_model.dart';
import '../core/constants/mock_data.dart';

/// FirebaseService - Manage Firebase initialization and workout library
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;
  bool _isOffline = false;

  /// Firebase initialization
  Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await _signInAnonymously();
    _initialized = true;
  }

  /// Anonymous Sign-in
  Future<void> _signInAnonymously() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        debugPrint('Signed in anonymously: ${auth.currentUser?.uid}');
      }
    } catch (e) {
      debugPrint('Anonymous sign in failed: $e (Falling back to offline mode)');
      _isOffline = true;
    }
  }

  /// Current User ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ============ Workout Library ============

  /// Convert mock WorkoutTaskModel to WorkoutTask entity
  List<WorkoutTask> _mockToEntities(Iterable<WorkoutTaskModel> models) {
    return models.map((m) => m.toEntity()).toList();
  }

  /// Fetch all workout list
  Future<List<WorkoutTask>> fetchWorkoutAllList() async {
    if (_isOffline) return _mockToEntities(mockWorkoutTasks);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .get();

      if (snapshot.docs.isEmpty) {
        return _mockToEntities(mockWorkoutTasks);
      }

      return snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error fetching workouts: $e');
      return _mockToEntities(mockWorkoutTasks);
    }
  }

  /// Search workouts by category
  Future<List<WorkoutTask>> searchWorkoutParts(String category) async {
    if (_isOffline) {
      return _mockToEntities(
        mockWorkoutTasks.where(
          (task) => task.category.toLowerCase() == category.toLowerCase(),
        ),
      );
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('category', isEqualTo: category.toLowerCase())
          .get();

      if (snapshot.docs.isEmpty) {
        return _mockToEntities(
          mockWorkoutTasks.where(
            (task) => task.category.toLowerCase() == category.toLowerCase(),
          ),
        );
      }

      return snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error searching workouts: $e');
      return _mockToEntities(
        mockWorkoutTasks.where(
          (task) => task.category.toLowerCase() == category.toLowerCase(),
        ),
      );
    }
  }

  /// Fetch specific workouts by IDs
  Future<List<WorkoutTask>> fetchWorkoutTask(
    List<String> workoutTaskIds,
  ) async {
    if (workoutTaskIds.isEmpty) return [];

    if (_isOffline) {
      return _mockToEntities(
        mockWorkoutTasks.where((task) => workoutTaskIds.contains(task.id)),
      );
    }

    try {
      if (workoutTaskIds.length > 10) {
        final all = await fetchWorkoutAllList();
        return all.where((t) => workoutTaskIds.contains(t.id)).toList();
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('id', whereIn: workoutTaskIds)
          .get();

      final fetched = snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()).toEntity())
          .toList();

      if (fetched.length < workoutTaskIds.length) {
        final foundIds = fetched.map((e) => e.id).toSet();
        final missingIds = workoutTaskIds.where((id) => !foundIds.contains(id));
        final mockFound = _mockToEntities(
          mockWorkoutTasks.where((task) => missingIds.contains(task.id)),
        );
        fetched.addAll(mockFound);
      }

      return fetched;
    } catch (e) {
      debugPrint('Error fetching workout tasks: $e');
      return _mockToEntities(
        mockWorkoutTasks.where((task) => workoutTaskIds.contains(task.id)),
      );
    }
  }

  /// Request workout media URLs via Cloud Function
  Future<List<WorkoutTask>> requestTaskUrls(List<WorkoutTask> tasks) async {
    if (tasks.isEmpty) return tasks;

    try {
      final taskIds = tasks.map((t) => t.id).toList();
      final result = await FirebaseFunctions.instance
          .httpsCallable('requestTaskInfo')
          .call({'task_ids': taskIds});

      final List<dynamic> taskUrls = result.data['task_urls'];
      final updatedTasks = <WorkoutTask>[];

      for (var task in tasks) {
        final taskData = taskUrls.firstWhere(
          (data) => data['id'] == task.id,
          orElse: () => null,
        );

        if (taskData != null) {
          updatedTasks.add(
            WorkoutTask(
              id: task.id,
              title: task.title,
              description: task.description,
              advice: task.advice,
              category: task.category,
              difficulty: task.difficulty,
              reps: task.reps,
              sets: task.sets,
              timeoutSec: task.timeoutSec,
              durationSec: task.durationSec,
              isCountable: task.isCountable,
              thumbnail: taskData['thumbnailUrl'] ?? task.thumbnail,
              readyPoseImageUrl:
                  taskData['readyPoseImageUrl'] ?? task.readyPoseImageUrl,
              exampleVideoUrl: taskData['videoUrl'] ?? task.exampleVideoUrl,
              configureUrl: taskData['configureUrl'] ?? task.configureUrl,
              guideAudioUrl: taskData['audioUrl'] ?? task.guideAudioUrl,
              coremlUrl: taskData['coremlUrl'] ?? task.coremlUrl,
              onnxUrl: taskData['onnxUrl'] ?? task.onnxUrl,
              adjustedReps: task.adjustedReps,
              adjustedSets: task.adjustedSets,
            ),
          );
        } else {
          updatedTasks.add(task);
        }
      }

      return updatedTasks;
    } catch (e) {
      debugPrint('Error calling requestTaskInfo: $e');
      return tasks;
    }
  }

  /// Workout list text for Gemini
  Future<String> getWorkoutListForGemini(String category) async {
    final tasks = await searchWorkoutParts(category);
    final buffer = StringBuffer();
    buffer.writeln('Available workouts for category "$category":');
    for (final task in tasks) {
      buffer.writeln('- ID: ${task.id}');
      buffer.writeln('  Title: ${task.title}');
      buffer.writeln('  Description: ${task.description}');
      buffer.writeln('  Difficulty: ${task.difficultyDisplayName}');
      buffer.writeln('  Default Reps: ${task.reps}, Sets: ${task.sets}');
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Fetch daily hot categories
  Future<List<String>> fetchDailyHotCategories() async {
    if (_isOffline) return mockDailyHotCategories;

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getDailyHotCategories')
          .call();

      final List<dynamic> categories = result.data['categories'];
      return categories.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error fetching daily hot categories: $e');
      return mockDailyHotCategories;
    }
  }

  /// Fetch featured program
  Future<WorkoutCurriculum?> fetchFeaturedProgram() async {
    try {
      Map<String, dynamic> data;

      if (_isOffline) {
        data = mockFeaturedPrograms['Build Strength']!;
      } else {
        try {
          final result = await FirebaseFunctions.instance
              .httpsCallable('getFeaturedProgram')
              .call({'category': 'Build Strength'});
          data = Map<String, dynamic>.from(result.data);
        } catch (e) {
          debugPrint('Error fetching featured program: $e');
          data = mockFeaturedPrograms['Build Strength']!;
        }
      }

      final taskIds = (data['task_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();

      final tasks = await fetchWorkoutTask(taskIds);

      final orderedTasks = <WorkoutTask>[];
      for (final id in taskIds) {
        if (tasks.any((t) => t.id == id)) {
          orderedTasks.add(tasks.firstWhere((t) => t.id == id));
        }
      }

      return WorkoutCurriculum(
        id: data['id'] ?? 'featured',
        title: data['title'] ?? 'Featured Program',
        description: data['description'] ?? '',
        workoutTasks: orderedTasks,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating featured program: $e');
      return null;
    }
  }
}
