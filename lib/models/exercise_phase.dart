enum ExercisePhase {
  ready,
  peak,
  movement,
  error,
  idle;

  /// Map model label string to ExercisePhase
  static ExercisePhase fromLabel(String label) {
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
