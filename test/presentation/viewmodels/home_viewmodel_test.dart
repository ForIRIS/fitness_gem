import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:fitness_gem/presentation/viewmodels/home_viewmodel.dart';
import 'package:fitness_gem/domain/entities/workout_curriculum.dart';
import 'package:fitness_gem/domain/entities/user_profile.dart';
import 'package:fitness_gem/domain/usecases/workout/get_today_curriculum.dart';
import 'package:fitness_gem/domain/usecases/workout/generate_curriculum.dart';
import 'package:fitness_gem/domain/usecases/workout/save_curriculum.dart';
import 'package:fitness_gem/domain/usecases/workout/get_daily_hot_categories.dart';
import 'package:fitness_gem/domain/usecases/workout/get_featured_program.dart';
import 'package:fitness_gem/domain/usecases/user/get_user_profile.dart';
import 'package:fitness_gem/core/error/failures.dart';

@GenerateMocks([
  GetTodayCurriculumUseCase,
  GenerateCurriculumUseCase,
  SaveCurriculumUseCase,
  GetDailyHotCategoriesUseCase,
  GetFeaturedProgramUseCase,
  GetUserProfileUseCase,
])
import 'home_viewmodel_test.mocks.dart';

void main() {
  late HomeViewModel viewModel;
  late MockGetTodayCurriculumUseCase mockGetTodayCurriculum;
  late MockGenerateCurriculumUseCase mockGenerateCurriculum;
  late MockSaveCurriculumUseCase mockSaveCurriculum;
  late MockGetDailyHotCategoriesUseCase mockGetDailyHotCategories;
  late MockGetFeaturedProgramUseCase mockGetFeaturedProgram;
  late MockGetUserProfileUseCase mockGetUserProfile;

  setUp(() {
    mockGetTodayCurriculum = MockGetTodayCurriculumUseCase();
    mockGenerateCurriculum = MockGenerateCurriculumUseCase();
    mockSaveCurriculum = MockSaveCurriculumUseCase();
    mockGetDailyHotCategories = MockGetDailyHotCategoriesUseCase();
    mockGetFeaturedProgram = MockGetFeaturedProgramUseCase();
    mockGetUserProfile = MockGetUserProfileUseCase();

    viewModel = HomeViewModel(
      getTodayCurriculum: mockGetTodayCurriculum,
      generateCurriculum: mockGenerateCurriculum,
      saveCurriculum: mockSaveCurriculum,
      getDailyHotCategories: mockGetDailyHotCategories,
      getFeaturedProgram: mockGetFeaturedProgram,
      getUserProfile: mockGetUserProfile,
    );
  });

  group('HomeViewModel', () {
    final tUserProfile = UserProfile(
      id: 'u1',
      nickname: 'Tester',
      age: 25,
      gender: 'Male',
      height: 175,
      weight: 70,
      fitnessLevel: 'Beginner',
      healthConditions: 'None',
      goal: 'Fitness',
      targetExercise: 'Squat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final tCurriculum = WorkoutCurriculum(
      id: '1',
      title: 'Test Curriculum',
      description: 'Test description',
      workoutTasks: [],
      createdAt: DateTime.now(),
    );
    final tCategories = ['Cardio', 'Strength'];

    test('initial state should be correct', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.todayCurriculum, null);
      expect(viewModel.userProfile, null);
      expect(viewModel.hotCategories, isEmpty);
    });

    test('loadData success flow', () async {
      // Arrange
      when(
        mockGetUserProfile.execute(),
      ).thenAnswer((_) async => Right(tUserProfile));
      when(
        mockGetTodayCurriculum.execute(),
      ).thenAnswer((_) async => Right(tCurriculum));
      when(
        mockGetDailyHotCategories.execute(),
      ).thenAnswer((_) async => Right(tCategories));
      when(
        mockGetFeaturedProgram.execute(),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final future = viewModel.loadData();

      // Assert loading state
      expect(viewModel.isLoading, true);

      await future;
      await Future.value(); // Pump event loop for unawaited properties

      // Assert final state
      expect(viewModel.isLoading, false);
      expect(viewModel.userProfile, tUserProfile);
      expect(viewModel.todayCurriculum, tCurriculum);
      expect(viewModel.hotCategories, tCategories);
    });

    test('generateNewCurriculum calls use case and updates state', () async {
      // Arrange
      // First set the profile so generation can proceed
      when(
        mockGetUserProfile.execute(),
      ).thenAnswer((_) async => Right(tUserProfile));
      when(
        mockGetTodayCurriculum.execute(),
      ).thenAnswer((_) async => const Right(null));
      when(
        mockGetDailyHotCategories.execute(),
      ).thenAnswer((_) async => const Right([]));
      when(
        mockGetFeaturedProgram.execute(),
      ).thenAnswer((_) async => const Right(null));

      when(
        mockGenerateCurriculum.execute(any),
      ).thenAnswer((_) async => Right(tCurriculum));

      await viewModel
          .loadData(); // Ensure profile is loaded and generation triggers

      // Act
      await viewModel.generateNewCurriculum();

      // Assert
      expect(viewModel.todayCurriculum, tCurriculum);
      verify(mockGenerateCurriculum.execute(tUserProfile));
    });
  });
}
