import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data sources
import '../../data/datasources/local/workout_local_datasource.dart';
import '../../data/datasources/local/user_local_datasource.dart';
import '../../data/datasources/remote/firebase_datasource.dart';
import '../../data/datasources/remote/gemini_datasource.dart';

// Repositories
import '../../domain/repositories/workout_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/exercise_repository_impl.dart';

// Use cases - Workout
import '../../domain/usecases/workout/get_today_curriculum.dart';
import '../../domain/usecases/workout/generate_curriculum.dart';
import '../../domain/usecases/workout/save_curriculum.dart';
import '../../domain/usecases/workout/get_daily_hot_categories.dart';
import '../../domain/usecases/workout/get_featured_program.dart';
import '../../domain/usecases/workout/get_exercise_config_usecase.dart';
import '../../domain/usecases/workout/get_available_workouts_usecase.dart';

// Use cases - User
import '../../domain/usecases/user/get_user_profile.dart';
import '../../domain/usecases/user/update_user_profile.dart';

// Use cases - AI
import '../../domain/usecases/ai/start_interview_usecase.dart';
import '../../domain/usecases/ai/send_interview_message_usecase.dart';
import '../../domain/usecases/ai/generate_curriculum_usecase.dart';
import '../../domain/usecases/ai/chat_for_curriculum_usecase.dart';
import '../../domain/usecases/ai/generate_curriculum_from_interview_usecase.dart';
import '../../domain/usecases/ai/chat_with_image_usecase.dart';
import '../../domain/usecases/ai/analyze_fall_detection_usecase.dart';
import '../../domain/usecases/ai/analyze_video_session_usecase.dart';
import '../../domain/usecases/ai/get_api_key_usecase.dart';
import '../../domain/usecases/ai/set_api_key_usecase.dart';

import '../../domain/repositories/ai_repository.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/datasources/gemini_remote_datasource.dart';
import '../../data/datasources/gemini_remote_datasource_impl.dart';
import '../../data/datasources/exercise_local_datasource.dart';
import '../../data/datasources/exercise_local_datasource_impl.dart';
import '../../data/datasources/exercise_remote_datasource.dart';
import '../../data/datasources/exercise_remote_datasource_impl.dart';
import '../../data/datasources/tts_feedback_output.dart';
import '../../services/cache_service.dart';
import '../../services/firebase_service.dart';
import '../../services/tts_service.dart';
import '../../domain/services/coaching_manager.dart';
import '../../domain/interfaces/feedback_output.dart';
// ViewModels
import '../../presentation/viewmodels/home_viewmodel.dart';

final getIt = GetIt.instance;

/// Initialize all dependencies for the application
Future<void> setupDependencyInjection() async {
  // ============ External Dependencies ============
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  // ============ Data Sources ============

  // Local Data Sources
  getIt.registerLazySingleton<WorkoutLocalDataSource>(
    () => WorkoutLocalDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(getIt()),
  );

  // Remote Data Sources
  getIt.registerLazySingleton<FirebaseDataSource>(
    () => FirebaseDataSourceImpl(),
  );

  getIt.registerLazySingleton<GeminiDataSource>(() => GeminiDataSourceImpl());
  getIt.registerLazySingleton<GeminiRemoteDataSource>(
    () => GeminiRemoteDataSourceImpl(),
  );

  getIt.registerLazySingleton(() => CacheService());
  getIt.registerLazySingleton(() => FirebaseService());

  getIt.registerLazySingleton<ExerciseLocalDataSource>(
    () => ExerciseLocalDataSourceImpl(cacheService: getIt()),
  );
  getIt.registerLazySingleton<ExerciseRemoteDataSource>(
    () => ExerciseRemoteDataSourceImpl(firebaseService: getIt()),
  );

  getIt.registerLazySingleton(() => TTSService());
  getIt.registerLazySingleton<FeedbackOutput>(
    () => TTSFeedbackOutput(ttsService: getIt()),
  );
  getIt.registerLazySingleton(() => CoachingManager(getIt()));

  // ============ Repositories ============

  getIt.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(
      localDataSource: getIt(),
      remoteDataSource: getIt(),
      aiDataSource: getIt(),
    ),
  );

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(localDataSource: getIt()),
  );

  getIt.registerLazySingleton<AIRepository>(
    () => AIRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
    ),
  );

  // ============ Use Cases - Workout ============

  getIt.registerLazySingleton(() => GetTodayCurriculumUseCase(getIt()));
  getIt.registerLazySingleton(() => GenerateCurriculumUseCase(getIt()));
  getIt.registerLazySingleton(() => SaveCurriculumUseCase(getIt()));
  getIt.registerLazySingleton(() => GetDailyHotCategoriesUseCase(getIt()));
  getIt.registerLazySingleton(() => GetFeaturedProgramUseCase(getIt()));
  getIt.registerLazySingleton(() => GetExerciseConfigUseCase(getIt()));
  getIt.registerLazySingleton(() => GetAvailableWorkoutsUseCase(getIt()));

  // ============ Use Cases - User ============

  getIt.registerLazySingleton(() => GetUserProfileUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateUserProfileUseCase(getIt()));

  // ============ Use Cases - AI ============

  getIt.registerLazySingleton(() => StartInterviewUseCase(getIt()));
  getIt.registerLazySingleton(() => SendInterviewMessageUseCase(getIt()));
  getIt.registerLazySingleton(() => GenerateAICurriculumUseCase(getIt()));
  getIt.registerLazySingleton(() => ChatForCurriculumUseCase(getIt()));
  getIt.registerLazySingleton(
    () => GenerateCurriculumFromInterviewUseCase(getIt()),
  );
  getIt.registerLazySingleton(() => ChatWithImageUseCase());
  getIt.registerLazySingleton(() => AnalyzeFallDetectionUseCase(getIt()));
  getIt.registerLazySingleton(() => AnalyzeVideoSessionUseCase(getIt()));
  getIt.registerLazySingleton(() => GetApiKeyUseCase(getIt()));
  getIt.registerLazySingleton(() => SetApiKeyUseCase(getIt()));

  // ============ ViewModels ============

  // Use factory for ViewModels so we get new instances each time
  getIt.registerFactory(
    () => HomeViewModel(
      getTodayCurriculum: getIt(),
      generateCurriculum: getIt(),
      saveCurriculum: getIt(),
      getDailyHotCategories: getIt(),
      getFeaturedProgram: getIt(),
      getUserProfile: getIt(),
    ),
  );
}
