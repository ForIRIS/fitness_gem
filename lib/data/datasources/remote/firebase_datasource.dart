import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/workout_task_model.dart';
import '../../../core/constants/mock_data.dart';

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

      if (snapshot.docs.isEmpty) {
        debugPrint('Firestore workouts empty for $category, using mock data');
        return mockWorkoutTasks
            .where((t) => t.category.toLowerCase() == category.toLowerCase())
            .toList();
      }

      return snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching workout tasks: $e, using mock data');
      return mockWorkoutTasks
          .where((t) => t.category.toLowerCase() == category.toLowerCase())
          .toList();
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

        if (allTasks.isEmpty) {
          return mockWorkoutTasks.where((t) => ids.contains(t.id)).toList();
        }
        return allTasks;
      }

      final snapshot = await _firestore
          .collection('workouts')
          .where('id', whereIn: ids)
          .get();

      if (snapshot.docs.isEmpty) {
        return mockWorkoutTasks.where((t) => ids.contains(t.id)).toList();
      }

      return snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching workout tasks by IDs: $e, using mock data');
      return mockWorkoutTasks.where((t) => ids.contains(t.id)).toList();
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
    if (_auth.currentUser == null) {
      return _getMockFeaturedProgramData();
    }

    try {
      final result = await _functions
          .httpsCallable('getFeaturedProgram')
          .call();

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error fetching featured program: $e');
      return _getMockFeaturedProgramData();
    }
  }

  Map<String, dynamic> _getMockFeaturedProgramData() {
    return {
      'id': 'summer_shred_mock',
      'title': 'Summer Shred Challenge',
      'description':
          'High-intensity routine to burn calories and build muscle.',
      'task_ids': [
        'squat_01',
        'push_01',
        'core_01',
        'squat_02',
        'push_02',
        'core_02',
      ],
      'imageUrl': 'assets/images/workouts/squat_01.png',
      'slogan': 'Get Set, Stay Ignite.',
      'membersCount': '5.8k+',
      'rating': 5.0,
      'difficulty': 3,
      'userAvatars': [],
    };
  }

  @override
  Future<void> requestTaskUrls(List<WorkoutTaskModel> tasks) async {
    if (tasks.isEmpty) return;

    try {
      final taskIds = tasks.map((t) => t.id).toList();
      final result = await _functions.httpsCallable('requestTaskInfo').call({
        'task_ids': taskIds,
      });

      final List<dynamic> taskUrls = result.data['task_urls'] ?? [];
      debugPrint('Received task URLs: ${taskUrls.length}');
    } catch (e) {
      debugPrint('Error requesting task URLs: $e');
    }
  }
}
