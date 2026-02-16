import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/workout_curriculum_model.dart';
import '../../models/featured_program_model.dart';

/// Local data source for workout-related data
abstract class WorkoutLocalDataSource {
  /// Get today's curriculum from local storage
  Future<WorkoutCurriculumModel?> getCurriculum();

  /// Save curriculum to local storage
  Future<void> saveCurriculum(WorkoutCurriculumModel curriculum);

  /// Clear curriculum from local storage
  Future<void> clearCurriculum();

  /// Get featured program from local storage
  Future<FeaturedProgramModel?> getFeaturedProgram(String category);

  /// Save featured program to local storage
  Future<void> saveFeaturedProgram(
    FeaturedProgramModel program,
    String category,
  );
}

class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _curriculumKey =
      'today_curriculum_v2'; // Bump version to clear stale cache
  static const String _featuredProgramKeyPrefix = 'featured_program_';

  WorkoutLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<WorkoutCurriculumModel?> getCurriculum() async {
    final jsonString = sharedPreferences.getString(_curriculumKey);
    if (jsonString != null) {
      debugPrint(
        'LocalDS: Found cached curriculum JSON length: ${jsonString.length}',
      );
      try {
        return WorkoutCurriculumModel.fromJson(jsonString);
      } catch (e) {
        debugPrint('LocalDS: Failed to parse cached curriculum: $e');
        return null;
      }
    }
    debugPrint('LocalDS: No cached curriculum found in prefs');
    return null;
  }

  @override
  Future<void> saveCurriculum(WorkoutCurriculumModel curriculum) async {
    debugPrint('LocalDS: Saving curriculum to prefs...');
    await sharedPreferences.setString(_curriculumKey, curriculum.toJson());
    debugPrint('LocalDS: Saved curriculum to prefs successfully');
  }

  @override
  Future<void> clearCurriculum() async {
    debugPrint('LocalDS: Clearing curriculum from prefs');
    await sharedPreferences.remove(_curriculumKey);
  }

  @override
  Future<FeaturedProgramModel?> getFeaturedProgram(String category) async {
    final key = '$_featuredProgramKeyPrefix${category.toLowerCase()}';
    final jsonString = sharedPreferences.getString(key);

    if (jsonString != null) {
      debugPrint(
        'LocalDS: Found cached featured program for $category (length: ${jsonString.length})',
      );
      try {
        return FeaturedProgramModel.fromJson(jsonString);
      } catch (e) {
        debugPrint(
          'LocalDS: Failed to parse cached featured program for $category: $e',
        );
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveFeaturedProgram(
    FeaturedProgramModel program,
    String category,
  ) async {
    final key = '$_featuredProgramKeyPrefix${category.toLowerCase()}';
    debugPrint('LocalDS: Saving featured program for $category to prefs...');
    await sharedPreferences.setString(key, program.toJson());
    debugPrint(
      'LocalDS: Saved featured program for $category to prefs successfully',
    );
  }
}
