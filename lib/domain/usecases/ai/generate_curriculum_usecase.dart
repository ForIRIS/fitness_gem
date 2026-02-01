import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';
import '../../entities/user_profile.dart';
import '../../entities/workout_task.dart';
import '../../entities/workout_curriculum.dart';

class GenerateAICurriculumUseCase
    implements UseCase<WorkoutCurriculum?, GenerateCurriculumParams> {
  final AIRepository repository;

  GenerateAICurriculumUseCase(this.repository);

  @override
  Future<Either<Failure, WorkoutCurriculum?>> execute(
    GenerateCurriculumParams params,
  ) async {
    return await repository.generateCurriculum(
      profile: params.profile,
      category: params.category,
      availableWorkouts: params.availableWorkouts,
    );
  }
}

class GenerateCurriculumParams {
  final UserProfile profile;
  final String category;
  final List<WorkoutTask> availableWorkouts;

  GenerateCurriculumParams({
    required this.profile,
    required this.category,
    required this.availableWorkouts,
  });
}
