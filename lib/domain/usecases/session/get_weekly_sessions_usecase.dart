import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/workout_session.dart';
import '../../repositories/session_repository.dart';

/// Use case for getting weekly sessions (last 7 days)
class GetWeeklySessionsUseCase {
  final SessionRepository repository;

  GetWeeklySessionsUseCase(this.repository);

  Future<Either<Failure, List<WorkoutSession>>> execute() {
    return repository.getWeeklySessions();
  }
}
