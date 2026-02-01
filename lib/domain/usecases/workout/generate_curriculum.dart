import 'package:dartz/dartz.dart';
import '../../entities/workout_curriculum.dart';
import '../../entities/user_profile.dart';
import '../../repositories/workout_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

/// Use case to generate a new workout curriculum based on user profile
class GenerateCurriculumUseCase
    implements UseCase<WorkoutCurriculum, UserProfile> {
  final WorkoutRepository repository;

  GenerateCurriculumUseCase(this.repository);

  @override
  Future<Either<Failure, WorkoutCurriculum>> execute(UserProfile params) async {
    return await repository.generateCurriculum(params);
  }
}
