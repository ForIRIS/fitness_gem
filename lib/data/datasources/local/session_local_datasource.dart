import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/workout_session_model.dart';

/// Local data source for workout session history
abstract class SessionLocalDataSource {
  /// Get all sessions within a date range
  Future<List<WorkoutSessionModel>> getSessionsInRange(
    DateTime start,
    DateTime end,
  );

  /// Get all sessions (for full history)
  Future<List<WorkoutSessionModel>> getAllSessions();

  /// Save a new workout session
  Future<void> saveSession(WorkoutSessionModel session);

  /// Delete a session by ID
  Future<void> deleteSession(String sessionId);

  /// Delete all sessions (for testing/reset)
  Future<void> deleteAllSessions();
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _sessionsKey = 'workout_sessions';

  SessionLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<List<WorkoutSessionModel>> getAllSessions() async {
    final jsonString = sharedPreferences.getString(_sessionsKey);
    if (jsonString == null) {
      debugPrint('SessionLocalDS: No sessions found');
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final sessions = jsonList
          .map(
            (json) => WorkoutSessionModel.fromMap(json as Map<String, dynamic>),
          )
          .toList();
      debugPrint('SessionLocalDS: Loaded ${sessions.length} sessions');
      return sessions;
    } catch (e) {
      debugPrint('SessionLocalDS: Failed to parse sessions: $e');
      return [];
    }
  }

  @override
  Future<List<WorkoutSessionModel>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final allSessions = await getAllSessions();
    return allSessions.where((session) {
      return session.date.isAfter(start.subtract(const Duration(days: 1))) &&
          session.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<void> saveSession(WorkoutSessionModel session) async {
    debugPrint('SessionLocalDS: Saving session ${session.id}');
    final allSessions = await getAllSessions();

    // Check if session already exists (update) or is new (add)
    final existingIndex = allSessions.indexWhere((s) => s.id == session.id);
    if (existingIndex >= 0) {
      allSessions[existingIndex] = session;
    } else {
      allSessions.add(session);
    }

    final jsonList = allSessions.map((s) => s.toMap()).toList();
    await sharedPreferences.setString(_sessionsKey, jsonEncode(jsonList));
    debugPrint(
      'SessionLocalDS: Session saved. Total sessions: ${allSessions.length}',
    );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    debugPrint('SessionLocalDS: Deleting session $sessionId');
    final allSessions = await getAllSessions();
    allSessions.removeWhere((s) => s.id == sessionId);

    final jsonList = allSessions.map((s) => s.toMap()).toList();
    await sharedPreferences.setString(_sessionsKey, jsonEncode(jsonList));
    debugPrint(
      'SessionLocalDS: Session deleted. Total sessions: ${allSessions.length}',
    );
  }

  @override
  Future<void> deleteAllSessions() async {
    debugPrint('SessionLocalDS: Deleting all sessions');
    await sharedPreferences.remove(_sessionsKey);
  }
}
