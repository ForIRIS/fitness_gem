enum ExercisePhase {
  ready,
  peak,
  movement,
  error,
  idle;

  /// Map model label string to ExercisePhase
  static ExercisePhase fromLabel(
    String label, {
    Map<String, dynamic>? classPhases,
  }) {
    // 1. Check explicit mapping first
    if (classPhases != null && classPhases.containsKey(label)) {
      final phaseStr = classPhases[label]?.toString().toUpperCase();
      if (phaseStr == 'READY') return ExercisePhase.ready;
      if (phaseStr == 'PEAK') return ExercisePhase.peak;
      if (phaseStr == 'MOVEMENT') return ExercisePhase.movement;
      if (phaseStr == 'IDLE') return ExercisePhase.idle;
      // Fallback if mapped value is unknown
    }

    // 2. Fallback to keyword matching
    final lowerLabel = label.toLowerCase();

    if (lowerLabel.contains('ready')) {
      return ExercisePhase.ready;
    } else if (lowerLabel.contains('peak')) {
      return ExercisePhase.peak;
    } else if (lowerLabel.contains('error')) {
      return ExercisePhase.error;
    } else if (lowerLabel.contains('idle')) {
      return ExercisePhase.idle;
    } else {
      return ExercisePhase.movement;
    }
  }
}
