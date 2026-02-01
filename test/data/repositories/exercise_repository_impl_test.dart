import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:fitness_gem/data/repositories/exercise_repository_impl.dart';
import 'package:fitness_gem/data/datasources/exercise_local_datasource.dart';
import 'package:fitness_gem/data/datasources/exercise_remote_datasource.dart';
import 'package:fitness_gem/domain/entities/exercise_config.dart';
import 'package:fitness_gem/domain/entities/workout_task.dart';
import 'package:fitness_gem/core/error/failures.dart';

// Generate mocks
@GenerateMocks([ExerciseLocalDataSource, ExerciseRemoteDataSource])
import 'exercise_repository_impl_test.mocks.dart';

void main() {
  late ExerciseRepositoryImpl repository;
  late MockExerciseLocalDataSource mockLocalDataSource;
  late MockExerciseRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockExerciseLocalDataSource();
    mockRemoteDataSource = MockExerciseRemoteDataSource();

    repository = ExerciseRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('getExerciseConfig', () {
    const tTask = WorkoutTask(
      id: '1',
      title: 'Squat',
      description: 'Squat',
      advice: 'Keep back straight',
      category: 'Strength',
      difficulty: 1,
      reps: 10,
      sets: 3,
      timeoutSec: 30,
      isCountable: true,
      configureUrl: 'http://example.com/config.json',
      exampleVideoUrl: 'http://example.com/video.mp4',
      guideAudioUrl: 'http://example.com/audio.mp3',
    );

    const tExerciseConfig = ExerciseConfig(id: 'config_1', category: 'Squat');

    test(
      'should return ExerciseConfig from local cache if available',
      () async {
        // Arrange
        when(
          mockLocalDataSource.getCachedExerciseConfig(any),
        ).thenAnswer((_) async => tExerciseConfig);

        // Act
        final result = await repository.getExerciseConfig(tTask);

        // Assert
        verify(mockLocalDataSource.getCachedExerciseConfig(tTask.configureUrl));
        expect(result, const Right(tExerciseConfig));
      },
    );

    test(
      'should return ExerciseConfig from remote if cache is empty',
      () async {
        // Arrange
        when(
          mockLocalDataSource.getCachedExerciseConfig(any),
        ).thenAnswer((_) async => null);
        when(
          mockRemoteDataSource.fetchExerciseConfig(any, any),
        ).thenAnswer((_) async => tExerciseConfig);
        when(
          mockLocalDataSource.cacheExerciseConfig(any, any),
        ).thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.getExerciseConfig(tTask);

        // Assert
        verify(mockLocalDataSource.getCachedExerciseConfig(tTask.configureUrl));
        verify(
          mockRemoteDataSource.fetchExerciseConfig(
            tTask.configureUrl,
            tTask.category,
          ),
        );
        verify(
          mockLocalDataSource.cacheExerciseConfig(
            tTask.configureUrl,
            tExerciseConfig,
          ),
        );
        expect(result, const Right(tExerciseConfig));
      },
    );

    test('should return ServerFailure when remote fetch fails', () async {
      // Arrange
      when(
        mockLocalDataSource.getCachedExerciseConfig(any),
      ).thenAnswer((_) async => null);
      when(
        mockRemoteDataSource.fetchExerciseConfig(any, any),
      ).thenThrow(Exception('Server Error'));

      // Act
      final result = await repository.getExerciseConfig(tTask);

      // Assert
      verify(
        mockRemoteDataSource.fetchExerciseConfig(
          tTask.configureUrl,
          tTask.category,
        ),
      );
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
    });
  });
}
