import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/entities/exercise_config.dart';
import '../../../domain/entities/workout_task.dart';
import '../../../services/firebase_service.dart';
import '../models/exercise_config_model.dart';
import 'exercise_remote_datasource.dart';

class ExerciseRemoteDataSourceImpl implements ExerciseRemoteDataSource {
  final FirebaseService _firebaseService;

  ExerciseRemoteDataSourceImpl({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  @override
  Future<ExerciseConfig> fetchExerciseConfig(
    String url,
    String category,
  ) async {
    if (!url.startsWith('http')) {
      throw Exception('Invalid URL: $url');
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final model = ExerciseConfigModel.fromMap(data, category: category);
      return model.toEntity();
    }

    throw Exception('Failed to fetch exercise config: ${response.statusCode}');
  }

  @override
  Future<List<WorkoutTask>> fetchWorkoutTasks() async {
    return await _firebaseService.fetchWorkoutAllList();
  }
}
