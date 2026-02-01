import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/workout_task_model.dart';
import '../../models/workout_curriculum_model.dart';

/// Remote data source for Firebase operations
abstract class FirebaseDataSource {
  Future<List<WorkoutTaskModel>> fetchWorkoutTasks(String category);
  Future<List<WorkoutTaskModel>> fetchWorkoutTasksByIds(List<String> ids);
  Future<List<String>> fetchDailyHotCategories();
  Future<Map<String, dynamic>> fetchFeaturedProgramData();
  Future<void> requestTaskUrls(List<WorkoutTaskModel> tasks);
}

class FirebaseDataSourceImpl implements FirebaseDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  FirebaseDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<List<WorkoutTaskModel>> fetchWorkoutTasks(String category) async {
    try {
      final snapshot = await _firestore
          .collection('workouts')
          .where('category', isEqualTo: category.toLowerCase())
          .get();

      return snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching workout tasks: $e');
      return [];
    }
  }

  @override
  Future<List<WorkoutTaskModel>> fetchWorkoutTasksByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];

    try {
      // Firestore whereIn limit is 10, so we need to batch
      if (ids.length > 10) {
        final List<WorkoutTaskModel> allTasks = [];
        for (int i = 0; i < ids.length; i += 10) {
          final batch = ids.skip(i).take(10).toList();
          final snapshot = await _firestore
              .collection('workouts')
              .where('id', whereIn: batch)
              .get();

          allTasks.addAll(
            snapshot.docs.map((doc) => WorkoutTaskModel.fromMap(doc.data())),
          );
        }
        return allTasks;
      }

      final snapshot = await _firestore
          .collection('workouts')
          .where('id', whereIn: ids)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching workout tasks by IDs: $e');

      // Fallback for mock IDs used in fetchFeaturedProgramData
      if (ids.contains('squat_04')) {
        return [
          const WorkoutTaskModel(
            id: 'squat_04',
            title: 'Air Squat',
            description: 'Basic bodyweight squat',
            advice: 'Keep chest up and weight on heels.',
            category: 'squat',
            difficulty: 1,
            reps: 20,
            sets: 3,
            timeoutSec: 30,
            durationSec: 120, // 2 mins
            isCountable: true,
          ),
          const WorkoutTaskModel(
            id: 'push_03',
            title: 'Push-up',
            description: 'Standard push-up',
            advice: 'Maintain a straight line from head to heels.',
            category: 'push',
            difficulty: 2,
            reps: 15,
            sets: 3,
            timeoutSec: 45,
            durationSec: 90,
            isCountable: true,
          ),
          const WorkoutTaskModel(
            id: 'lunge_03',
            title: 'Walking Lunge',
            description: 'Bodyweight lunges while walking.',
            advice: 'Step forward and lower hips.',
            category: 'lunge',
            difficulty: 2,
            reps: 12,
            sets: 3,
            timeoutSec: 45,
            durationSec: 150,
            isCountable: true,
          ),
        ];
      }
      return [];
    }
  }

  @override
  Future<List<String>> fetchDailyHotCategories() async {
    try {
      final result = await _functions
          .httpsCallable('getDailyHotCategories')
          .call();

      final List<dynamic> categories = result.data['categories'];
      return categories.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error fetching daily hot categories: $e');
      // Return mock data on error
      return [
        'Upper Body',
        'Build Strength',
        'Beginner',
        'Core Workout',
        'Lower Body',
        'HIIT Training',
      ];
    }
  }

  @override
  Future<Map<String, dynamic>> fetchFeaturedProgramData() async {
    try {
      final result = await _functions
          .httpsCallable('getFeaturedProgram')
          .call();

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error fetching featured program: $e');
      // Return mock data on error
      return {
        'id': 'summer_shred_mock',
        'title': 'Summer Shred Challenge',
        'description':
            'High-intensity routine to burn calories and build muscle.',
        'task_ids': [
          'squat_04',
          'push_03',
          'lunge_03',
          'core_03',
          'squat_03',
          'push_02',
        ],
        'imageUrl': 'assets/images/workouts/squat_04.png',
        'slogan': 'Get Set, Stay Ignite.',
        'membersCount': '5.8k+',
        'rating': 5.0,
        'difficulty': 3,
        'userAvatars': [
          'https://i.pravatar.cc/150?img=12',
          'https://i.pravatar.cc/150?img=24',
          'https://i.pravatar.cc/150?img=33',
        ],
      };
    }
  }

  @override
  Future<void> requestTaskUrls(List<WorkoutTaskModel> tasks) async {
    if (tasks.isEmpty) return;

    try {
      final taskIds = tasks.map((t) => t.id).toList();
      final result = await _functions.httpsCallable('requestTaskInfo').call({
        'task_ids': taskIds,
      });

      final List<dynamic> taskUrls = result.data['task_urls'];

      // Note: This method would need to update the tasks
      // In a pure architecture, we might return the URLs instead
      // For now, keeping it simple
      debugPrint('Received task URLs: ${taskUrls.length}');
    } catch (e) {
      debugPrint('Error requesting task URLs: $e');
    }
  }
}
