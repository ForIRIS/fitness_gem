import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';
import '../../entities/user_profile.dart';
import '../../entities/workout_task.dart';
import '../../entities/workout_curriculum.dart';

class GenerateCurriculumFromInterviewUseCase
    implements
        UseCase<WorkoutCurriculum?, GenerateCurriculumFromInterviewParams> {
  final AIRepository repository;

  GenerateCurriculumFromInterviewUseCase(this.repository);

  @override
  Future<Either<Failure, WorkoutCurriculum?>> execute(
    GenerateCurriculumFromInterviewParams params,
  ) async {
    return await repository.generateCurriculumFromInterviewResult(
      profile: params.profile,
      availableWorkouts: params.availableWorkouts,
      interviewDetails: params.interviewDetails,
    );
  }
}

class GenerateCurriculumFromInterviewParams {
  final UserProfile profile;
  final List<WorkoutTask> availableWorkouts;
  final Map<String, String> interviewDetails;

  GenerateCurriculumFromInterviewParams({
    required this.profile,
    required this.availableWorkouts,
    required this.interviewDetails,
  });
}
