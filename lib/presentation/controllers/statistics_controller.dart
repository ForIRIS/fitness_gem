import 'package:flutter/foundation.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/usecases/session/get_weekly_sessions_usecase.dart';
import '../../domain/usecases/session/get_previous_week_sessions_usecase.dart';
import '../../core/di/injection.dart';

/// Controller for statistics and progress analysis
class StatisticsController extends ChangeNotifier {
  final GetWeeklySessionsUseCase _getWeeklySessions =
      getIt<GetWeeklySessionsUseCase>();
  final GetPreviousWeekSessionsUseCase _getPreviousWeekSessions =
      getIt<GetPreviousWeekSessionsUseCase>();

  List<WorkoutSession> _currentWeekSessions = [];
  List<WorkoutSession> _previousWeekSessions = [];
  bool _isLoading = false;

  List<WorkoutSession> get currentWeekSessions => _currentWeekSessions;
  List<WorkoutSession> get previousWeekSessions => _previousWeekSessions;
  bool get isLoading => _isLoading;

  /// Load sessions for current week and previous week
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final weeklyResult = await _getWeeklySessions.execute();
    final previousResult = await _getPreviousWeekSessions.execute();

    weeklyResult.fold(
      (failure) => debugPrint('Failed to load current week sessions: $failure'),
      (sessions) => _currentWeekSessions = sessions,
    );

    previousResult.fold(
      (failure) =>
          debugPrint('Failed to load previous week sessions: $failure'),
      (sessions) => _previousWeekSessions = sessions,
    );

    _isLoading = false;
    notifyListeners();
  }

  // ============ Progress Analysis ============

  /// Calculate week-over-week workout count change
  double get workoutCountChange {
    if (_previousWeekSessions.isEmpty) return 0;
    final current = _currentWeekSessions.length.toDouble();
    final previous = _previousWeekSessions.length.toDouble();
    return ((current - previous) / previous) * 100;
  }

  /// Calculate week-over-week duration change
  double get durationChange {
    final currentDuration = _currentWeekSessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    final previousDuration = _previousWeekSessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );

    if (previousDuration == 0) return 0;
    return ((currentDuration - previousDuration) / previousDuration) * 100;
  }

  /// Calculate week-over-week reps change
  double get repsChange {
    final currentReps = _currentWeekSessions.fold<int>(
      0,
      (sum, s) => sum + s.totalReps,
    );
    final previousReps = _previousWeekSessions.fold<int>(
      0,
      (sum, s) => sum + s.totalReps,
    );

    if (previousReps == 0) return 0;
    return ((currentReps - previousReps) / previousReps) * 100;
  }

  /// Total workout count this week
  int get totalWorkouts => _currentWeekSessions.length;

  /// Total duration in minutes this week
  int get totalDurationMinutes {
    final seconds = _currentWeekSessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    return (seconds / 60).ceil();
  }

  /// Total reps this week
  int get totalReps =>
      _currentWeekSessions.fold<int>(0, (sum, s) => sum + s.totalReps);

  /// Average form score this week
  double get avgFormScore {
    if (_currentWeekSessions.isEmpty) return 0;
    return _currentWeekSessions.fold<double>(
          0,
          (sum, s) => sum + s.avgFormScore,
        ) /
        _currentWeekSessions.length;
  }

  // ============ Dynamic Feedback ============

  /// Generate dynamic feedback text based on performance
  String get feedbackTitle {
    if (_currentWeekSessions.isEmpty) {
      return 'Ready to Start?';
    }

    if (workoutCountChange > 20) {
      return '🔥 On Fire!';
    } else if (workoutCountChange > 0) {
      return '📈 Making Progress!';
    } else if (totalWorkouts >= 3) {
      return '💪 Staying Consistent!';
    } else if (totalWorkouts >= 1) {
      return '👍 Good Start!';
    }
    return '💫 Keep Going!';
  }

  /// Generate detailed feedback message
  String get feedbackMessage {
    if (_currentWeekSessions.isEmpty) {
      return 'Complete your first workout to start tracking your progress!';
    }

    final buffer = StringBuffer();

    // Workout count insight
    buffer.write('You completed $totalWorkouts workout');
    buffer.write(totalWorkouts == 1 ? '' : 's');
    buffer.write(' this week');

    if (_previousWeekSessions.isNotEmpty && workoutCountChange != 0) {
      buffer.write(workoutCountChange > 0 ? ' — ' : ' — ');
      buffer.write('${workoutCountChange.abs().toStringAsFixed(0)}% ');
      buffer.write(workoutCountChange > 0 ? 'more' : 'less');
      buffer.write(' than last week');
    }

    buffer.write('.');

    // Duration insight
    if (totalDurationMinutes > 0) {
      buffer.write(' Total time: $totalDurationMinutes minutes.');
    }

    // Reps insight
    if (totalReps > 0) {
      buffer.write(' Total reps: $totalReps.');
    }

    return buffer.toString();
  }

  /// Get motivational message based on streak or consistency
  String get motivationalMessage {
    if (_currentWeekSessions.isEmpty) {
      return 'Your fitness journey starts now!';
    }

    if (avgFormScore >= 0.8) {
      return 'Excellent form! Keep maintaining that quality.';
    } else if (totalWorkouts >= 5) {
      return 'Incredible dedication this week!';
    } else if (totalWorkouts >= 3) {
      return 'Great consistency! You\'re building a strong habit.';
    } else if (durationChange > 0) {
      return 'Nice! You\'re spending more time on your fitness.';
    }

    return 'Every workout counts. Keep pushing!';
  }

  /// Get color indicator for change (positive = green, negative = red)
  bool get isPositiveChange => workoutCountChange >= 0;
}
