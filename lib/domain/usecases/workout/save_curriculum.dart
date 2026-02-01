import 'package:dartz/dartz.dart';
import '../../entities/workout_curriculum.dart';
import '../../repositories/workout_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

/// Use case to save workout curriculum
class SaveCurriculumUseCase implements UseCase<void, WorkoutCurriculum> {
  final WorkoutRepository repository;

  SaveCurriculumUseCase(this.repository);

  @override
  Future<Either<Failure, void>> execute(WorkoutCurriculum params) async {
    return await repository.saveCurriculum(params);
  }
}
