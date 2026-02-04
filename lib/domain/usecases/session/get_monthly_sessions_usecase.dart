import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/workout_session.dart';
import '../../repositories/session_repository.dart';

/// Use case for getting monthly sessions (last 30 days)
class GetMonthlySessionsUseCase {
  final SessionRepository repository;

  GetMonthlySessionsUseCase(this.repository);

  Future<Either<Failure, List<WorkoutSession>>> execute() {
    return repository.getMonthlySessions();
  }
}
