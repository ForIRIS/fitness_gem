enum CountingMode {
  /// Traditional sequential counting (1, 2, 3...)
  sequential,

  /// Count occurrences (e.g., shadow boxing punches)
  singleAction,

  /// Left + Right = 1 Rep (e.g., alternating lunges)
  alternatingFullCycle,

  /// Left = 1, Right = 1 (tracked separately)
  alternatingPerSide,

  /// Count time in target zone (1 rep = 1 second)
  duration;

  /// Parse from string (case-insensitive)
  static CountingMode fromString(String? value) {
    if (value == null) return CountingMode.sequential;
    final normalized = value.toUpperCase();
    switch (normalized) {
      case 'SINGLE_ACTION':
        return CountingMode.singleAction;
      case 'ALTERNATING_FULL_CYCLE':
        return CountingMode.alternatingFullCycle;
      case 'ALTERNATING_PER_SIDE':
        return CountingMode.alternatingPerSide;
      case 'DURATION':
      case 'STATIC':
        return CountingMode.duration;
      case 'SEQUENTIAL':
      default:
        return CountingMode.sequential;
    }
  }
}
