import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/ai_repository.dart';
import '../../entities/post_workout_summary.dart';

/// UseCase: Generate post-workout summary using the Storyteller agent
/// Compares current session performance against baseline and returns UI-ready data.
class GeneratePostWorkoutSummaryUseCase {
  final AIRepository repository;

  GeneratePostWorkoutSummaryUseCase(this.repository);

  Future<Either<Failure, PostWorkoutSummary?>> execute({
    required String userLanguage,
    required String exerciseName,
    required int initialStability,
    required int initialMobility,
    required int sessionStability,
    required int totalReps,
    String? primaryFaultDetected,
  }) async {
    final result = await repository.generatePostWorkoutSummary(
      userLanguage: userLanguage,
      exerciseName: exerciseName,
      initialStability: initialStability,
      initialMobility: initialMobility,
      sessionStability: sessionStability,
      totalReps: totalReps,
      primaryFaultDetected: primaryFaultDetected,
    );

    return result.fold((failure) => Left(failure), (jsonData) {
      if (jsonData == null) return const Right(null);
      try {
        return Right(PostWorkoutSummary.fromJson(jsonData));
      } catch (e) {
        return Left(ServerFailure('Failed to parse summary: $e'));
      }
    });
  }
}
