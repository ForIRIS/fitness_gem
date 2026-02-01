import 'package:shared_preferences/shared_preferences.dart';
import '../../models/workout_curriculum_model.dart';

/// Local data source for workout-related data
abstract class WorkoutLocalDataSource {
  /// Get today's curriculum from local storage
  Future<WorkoutCurriculumModel?> getCurriculum();

  /// Save curriculum to local storage
  Future<void> saveCurriculum(WorkoutCurriculumModel curriculum);

  /// Clear curriculum from local storage
  Future<void> clearCurriculum();
}

class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _curriculumKey = 'today_curriculum';

  WorkoutLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<WorkoutCurriculumModel?> getCurriculum() async {
    final jsonString = sharedPreferences.getString(_curriculumKey);
    if (jsonString != null) {
      return WorkoutCurriculumModel.fromJson(jsonString);
    }
    return null;
  }

  @override
  Future<void> saveCurriculum(WorkoutCurriculumModel curriculum) async {
    await sharedPreferences.setString(_curriculumKey, curriculum.toJson());
  }

  @override
  Future<void> clearCurriculum() async {
    await sharedPreferences.remove(_curriculumKey);
  }
}
