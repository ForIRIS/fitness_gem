import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/workout_session.dart';
import '../../repositories/session_repository.dart';

/// Use case for saving a completed workout session
class SaveSessionUseCase {
  final SessionRepository repository;

  SaveSessionUseCase(this.repository);

  Future<Either<Failure, void>> execute(WorkoutSession session) {
    return repository.saveSession(session);
  }
}
