import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';
import '../../entities/user_profile.dart';
import '../../entities/workout_task.dart';
import '../../entities/workout_curriculum.dart';

class ChatForCurriculumUseCase
    implements UseCase<WorkoutCurriculum?, ChatForCurriculumParams> {
  final AIRepository repository;

  ChatForCurriculumUseCase(this.repository);

  @override
  Future<Either<Failure, WorkoutCurriculum?>> execute(
    ChatForCurriculumParams params,
  ) async {
    return await repository.chatForCurriculum(
      userMessage: params.userMessage,
      profile: params.profile,
      availableWorkouts: params.availableWorkouts,
    );
  }
}

class ChatForCurriculumParams {
  final String userMessage;
  final UserProfile profile;
  final List<WorkoutTask> availableWorkouts;

  ChatForCurriculumParams({
    required this.userMessage,
    required this.profile,
    required this.availableWorkouts,
  });
}
