import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/workout_session.dart';
import '../../repositories/session_repository.dart';

/// Use case for getting sessions from the previous week (7-14 days ago)
class GetPreviousWeekSessionsUseCase {
  final SessionRepository repository;

  GetPreviousWeekSessionsUseCase(this.repository);

  Future<Either<Failure, List<WorkoutSession>>> execute() {
    final now = DateTime.now();
    final startOfCurrentWeek = now.subtract(const Duration(days: 7));
    final startOfPreviousWeek = now.subtract(const Duration(days: 14));

    // Range: [14 days ago, 7 days ago]
    return repository.getSessionsInRange(
      startOfPreviousWeek,
      startOfCurrentWeek,
    );
  }
}
