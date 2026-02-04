import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/local/session_local_datasource.dart';
import '../models/workout_session_model.dart';

/// Implementation of SessionRepository
class SessionRepositoryImpl implements SessionRepository {
  final SessionLocalDataSource localDataSource;

  SessionRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<WorkoutSession>>> getAllSessions() async {
    try {
      final models = await localDataSource.getAllSessions();
      final sessions = models.map((m) => m.toEntity()).toList();
      // Sort by date descending (newest first)
      sessions.sort((a, b) => b.date.compareTo(a.date));
      return Right(sessions);
    } catch (e) {
      debugPrint('SessionRepo: Failed to get all sessions: $e');
      return Left(CacheFailure('Failed to load sessions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutSession>>> getWeeklySessions() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return getSessionsInRange(weekAgo, now);
  }

  @override
  Future<Either<Failure, List<WorkoutSession>>> getMonthlySessions() async {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return getSessionsInRange(monthAgo, now);
  }

  @override
  Future<Either<Failure, List<WorkoutSession>>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final models = await localDataSource.getSessionsInRange(start, end);
      final sessions = models.map((m) => m.toEntity()).toList();
      // Sort by date descending
      sessions.sort((a, b) => b.date.compareTo(a.date));
      return Right(sessions);
    } catch (e) {
      debugPrint('SessionRepo: Failed to get sessions in range: $e');
      return Left(CacheFailure('Failed to load sessions: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSession(WorkoutSession session) async {
    try {
      debugPrint('SessionRepo: Saving session ${session.id}');
      final model = WorkoutSessionModel.fromEntity(session);
      await localDataSource.saveSession(model);
      return const Right(null);
    } catch (e) {
      debugPrint('SessionRepo: Failed to save session: $e');
      return Left(CacheFailure('Failed to save session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(String sessionId) async {
    try {
      await localDataSource.deleteSession(sessionId);
      return const Right(null);
    } catch (e) {
      debugPrint('SessionRepo: Failed to delete session: $e');
      return Left(CacheFailure('Failed to delete session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllSessions() async {
    try {
      await localDataSource.deleteAllSessions();
      return const Right(null);
    } catch (e) {
      debugPrint('SessionRepo: Failed to delete all sessions: $e');
      return Left(CacheFailure('Failed to delete sessions: $e'));
    }
  }
}
