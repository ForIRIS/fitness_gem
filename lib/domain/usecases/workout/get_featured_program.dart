import 'package:dartz/dartz.dart';
import '../../entities/workout_curriculum.dart';
import '../../repositories/workout_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

/// Use case to get featured program
class GetFeaturedProgramUseCase implements NoParamsUseCase<WorkoutCurriculum?> {
  final WorkoutRepository repository;

  GetFeaturedProgramUseCase(this.repository);

  @override
  Future<Either<Failure, WorkoutCurriculum?>> execute() async {
    return await repository.getFeaturedProgram();
  }
}
