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
  Future<Map<String, dynamic>> fetchFeaturedProgramData([String? category]);
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

    // Optimization: Check if all IDs exist in local mock data first
    // This provides instant loading for the featured program mock data
    final localMatches = mockWorkoutTasks
        .where((t) => ids.contains(t.id))
        .toList();

    if (localMatches.length == ids.length) {
      return localMatches;
    }

    try {
      // If we are missing some, try to fetch from Firestore
      // ... (rest of the logic if needed, but for now fallback to Firestore then mock)

      // Firestore whereIn limit is 10
      if (ids.length > 10) {
        // ... existing batch logic or simplify ...
        // For now, let's keep it simple as we prioritized local mock
        return localMatches; // Fallback to what we have if network is not needed
      }

      final snapshot = await _firestore
          .collection('workouts')
          .where('id', whereIn: ids)
          .get();

      final tasks = snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()))
          .toList();

      // Check if we are missing any tasks
      if (tasks.length < ids.length) {
        final foundIds = tasks.map((t) => t.id).toSet();
        final missingIds = ids.where((id) => !foundIds.contains(id));

        final mockTasks = mockWorkoutTasks
            .where((t) => missingIds.contains(t.id))
            .toList();

        tasks.addAll(mockTasks);
      }

      return tasks;
    } catch (e) {
      debugPrint('Error fetching workout tasks by IDs: $e, using mock data');
      return mockWorkoutTasks.where((t) => ids.contains(t.id)).toList();
    }
  }

  // 1. 카테고리 목록
  final List<String> categories = ['Upper Body', 'Build Strength', 'Beginner'];

  // 2. 카테고리별 챌린지 데이터 매핑
  final Map<String, dynamic> challengeMockData = {
    // Case A: Build Strength (기존 데이터 활용)
    'Build Strength': {
      'id': 'summer_shred_mock',
      'title': 'Summer Shred Challenge',
      'slogan': 'Get Set, Stay Ignite.',
      'description':
          'High-intensity routine to burn calories and build muscle.',
      'imageUrl': 'assets/images/workouts/squat_04.png', // Jump sqaut image
      'membersCount': '5.8k+',
      'rating': 5.0,
      'difficulty': '3', // String type consistency
      'duration': '18 Min',
      'task_ids': [
        'squat_04',
        'push_03',
        'lunge_03',
        'core_03',
        'squat_03',
        'push_02',
      ], // Added task_ids to prevent crash
      'userAvatars': [
        'https://i.pravatar.cc/150?img=11',
        'https://i.pravatar.cc/150?img=12',
        'https://i.pravatar.cc/150?img=33',
        'https://i.pravatar.cc/150?img=5',
      ],
    },

    // Case B: Upper Body (상체 집중 챌린지)
    'Upper Body': {
      'id': 'upper_blast_mock',
      'title': 'Boulder Shoulders 30',
      'slogan': 'Sculpt Your Upper Body.',
      'description':
          'Focus on deltoids and chest with this intense dumbbell circuit.',
      'imageUrl': 'assets/images/workouts/push_01.png', // 푸쉬업하는 이미지 필요
      'membersCount': '2.1k+',
      'rating': 4.8,
      'difficulty': '4', // String type consistency
      'duration': '20 Min',
      'task_ids': [
        'push_01',
        'push_02',
        'core_01',
        'core_02',
      ], // Added task_ids
      'userAvatars': [
        'https://i.pravatar.cc/150?img=59',
        'https://i.pravatar.cc/150?img=60',
        'https://i.pravatar.cc/150?img=3',
      ],
    },

    // Case C: Beginner (초보자용)
    'Beginner': {
      'id': 'starter_mock',
      'title': 'Zero to Hero: Week 1',
      'slogan': 'Start Your Journey Today.',
      'description': 'Low impact movements designed for absolute beginners.',
      'imageUrl': 'assets/images/workouts/squat_01.png', // 스트레칭 이미지 필요
      'membersCount': '12k+',
      'rating': 4.9,
      'difficulty': '1', // String type consistency
      'duration': '10 Min',
      'task_ids': ['squat_01', 'core_01'], // Added task_ids
      'userAvatars': [
        'https://i.pravatar.cc/150?img=1',
        'https://i.pravatar.cc/150?img=2',
        'https://i.pravatar.cc/150?img=3',
        'https://i.pravatar.cc/150?img=4',
        'https://i.pravatar.cc/150?img=5',
      ],
    },
  };

  @override
  Future<List<String>> fetchDailyHotCategories() async {
    // Return the static list as requested
    return categories;
  }

  @override
  Future<Map<String, dynamic>> fetchFeaturedProgramData([
    String? category,
  ]) async {
    // Determine which category to show. Default to 'Build Strength' if null or not found.
    final targetCategory =
        (category != null && challengeMockData.containsKey(category))
        ? category
        : 'Build Strength';

    // Return the mock data for that category
    return challengeMockData[targetCategory] as Map<String, dynamic>;
  }

  // Deprecated/Unused helper, but kept for interface satisfaction if needed internally
  Map<String, dynamic> _getMockFeaturedProgramData() {
    return challengeMockData['Build Strength'] as Map<String, dynamic>;
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
