import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/exercise_config.dart';
import '../../entities/workout_task.dart';
import '../../repositories/exercise_repository.dart';

class GetExerciseConfigUseCase
    implements UseCase<ExerciseConfig, GetExerciseConfigParams> {
  final ExerciseRepository repository;

  GetExerciseConfigUseCase(this.repository);

  @override
  Future<Either<Failure, ExerciseConfig>> execute(
    GetExerciseConfigParams params,
  ) async {
    return await repository.getExerciseConfig(
      params.task,
      useMock: params.useMock,
    );
  }
}

class GetExerciseConfigParams {
  final WorkoutTask task;
  final bool useMock;

  GetExerciseConfigParams({required this.task, this.useMock = false});
}
