import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../models/workout_task_model.dart';
import '../../../core/constants/mock_data.dart';
import '../../../services/connectivity_service.dart';

/// Remote data source for Firebase operations
abstract class FirebaseDataSource {
  Future<List<WorkoutTaskModel>> fetchWorkoutTasks(String category);
  Future<List<WorkoutTaskModel>> fetchWorkoutTasksByIds(List<String> ids);
  Future<List<String>> fetchDailyHotCategories();
  Future<Map<String, dynamic>> fetchFeaturedProgramData([String? category]);
}

class FirebaseDataSourceImpl implements FirebaseDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final ConnectivityService _connectivityService;

  FirebaseDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    ConnectivityService? connectivityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _connectivityService = connectivityService ?? ConnectivityService();

  void _markUsingMockData(String reason) {
    debugPrint('FirebaseDataSource: $reason, using mock data');
    // Only set global mock flag if we're actually disconnected
    if (!_connectivityService.isConnected) {
      _connectivityService.setUsingMockData(true);
    }
  }

  @override
  Future<List<WorkoutTaskModel>> fetchWorkoutTasks(String category) async {
    try {
      final snapshot = await _firestore
          .collection('exercises')
          .where('category', isEqualTo: category.toLowerCase())
          .get();

      if (snapshot.docs.isEmpty) {
        _markUsingMockData('Firestore workouts empty for $category');
        return mockWorkoutTasks
            .where((t) => t.category.toLowerCase() == category.toLowerCase())
            .toList();
      }

      return snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _markUsingMockData('Error fetching workout tasks: $e');
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

    // Check local mock data first for instant loading
    final localMatches = mockWorkoutTasks
        .where((t) => ids.contains(t.id))
        .toList();
    if (localMatches.length == ids.length) {
      // All found in mock - this is intentional for speed, not a fallback
      return localMatches;
    }

    try {
      // Firestore whereIn limit is 10
      if (ids.length > 10) {
        _markUsingMockData('ID list > 10, Firestore limit');
        return localMatches;
      }

      final snapshot = await _firestore
          .collection('exercises')
          .where('id', whereIn: ids)
          .get();

      final tasks = snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()))
          .toList();

      // Fill missing with mock data
      if (tasks.length < ids.length) {
        final foundIds = tasks.map((t) => t.id).toSet();
        final missingIds = ids.where((id) => !foundIds.contains(id));
        final mockTasks = mockWorkoutTasks
            .where((t) => missingIds.contains(t.id))
            .toList();
        if (mockTasks.isNotEmpty) {
          _markUsingMockData('Partial data from Firestore, filling gaps');
        }
        tasks.addAll(mockTasks);
      }

      return tasks;
    } catch (e) {
      _markUsingMockData('Error fetching workout tasks by IDs: $e');
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
      _markUsingMockData('Error fetching daily hot categories: $e');
      return mockDailyHotCategories;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchFeaturedProgramData([
    String? category,
  ]) async {
    try {
      final result = await _functions.httpsCallable('getFeaturedProgram').call({
        'category': category ?? 'Build Strength',
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      _markUsingMockData('Error fetching featured program: $e');
      final targetCategory =
          (category != null && mockFeaturedPrograms.containsKey(category))
          ? category
          : 'Build Strength';
      return mockFeaturedPrograms[targetCategory]!;
    }
  }
}
