import 'package:dartz/dartz.dart';
import '../entities/workout_session.dart';
import '../../core/error/failures.dart';

/// Repository interface for workout session history
abstract class SessionRepository {
  /// Get all sessions
  Future<Either<Failure, List<WorkoutSession>>> getAllSessions();

  /// Get sessions from the last 7 days
  Future<Either<Failure, List<WorkoutSession>>> getWeeklySessions();

  /// Get sessions from the last 30 days
  Future<Either<Failure, List<WorkoutSession>>> getMonthlySessions();

  /// Get sessions within a date range
  Future<Either<Failure, List<WorkoutSession>>> getSessionsInRange(
    DateTime start,
    DateTime end,
  );

  /// Save a completed workout session
  Future<Either<Failure, void>> saveSession(WorkoutSession session);

  /// Delete a session by ID
  Future<Either<Failure, void>> deleteSession(String sessionId);

  /// Delete all sessions
  Future<Either<Failure, void>> deleteAllSessions();
}
