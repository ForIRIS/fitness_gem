import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/workout_task.dart';
import '../../repositories/exercise_repository.dart';

class GetAvailableWorkoutsUseCase
    implements UseCase<List<WorkoutTask>, GetAvailableWorkoutsParams> {
  final ExerciseRepository repository;

  GetAvailableWorkoutsUseCase(this.repository);

  @override
  Future<Either<Failure, List<WorkoutTask>>> call(
    GetAvailableWorkoutsParams params,
  ) async {
    return await repository.getAvailableWorkouts(
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetAvailableWorkoutsParams {
  final bool forceRefresh;

  GetAvailableWorkoutsParams({this.forceRefresh = false});
}
