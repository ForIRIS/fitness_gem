import 'dart:async';

class WorkoutTimerService {
  Timer? _workoutTimer;
  Timer? _countdownTimer;

  // Callbacks
  Function(int elapsed)? onWorkoutTick;
  Function()? onWorkoutTimeout;

  Function(int remaining)? onCountdownTick;
  Function()? onCountdownComplete;

  void startWorkoutTimer({
    required int timeoutSeconds,
    int initialElapsed = 0,
  }) {
    stopWorkoutTimer();

    int elapsed = initialElapsed;

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed++;
      onWorkoutTick?.call(elapsed);

      if (elapsed >= timeoutSeconds) {
        timer.cancel();
        onWorkoutTimeout?.call();
      }
    });
  }

  void stopWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = null;
  }

  void startCountdown(int seconds) {
    cancelCountdown();

    int remaining = seconds;
    // Initial tick
    onCountdownTick?.call(remaining);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining > 0) {
        onCountdownTick?.call(remaining);
      } else {
        timer.cancel();
        _countdownTimer = null;
        onCountdownComplete?.call();
      }
    });
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void dispose() {
    stopWorkoutTimer();
    cancelCountdown();
  }
}
