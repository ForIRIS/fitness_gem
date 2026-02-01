/// ExerciseModelOutput - Representation of the frame-by-frame model inference result
class ExerciseModelOutput {
  final List<double> phaseProbs;
  final double deviationScore;
  final List<double> currentFeatures;

  ExerciseModelOutput({
    required this.phaseProbs,
    required this.deviationScore,
    required this.currentFeatures,
  });

  factory ExerciseModelOutput.fromMap(Map<String, dynamic> map) {
    return ExerciseModelOutput(
      phaseProbs:
          (map['phase_probs'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      deviationScore: (map['deviation_score'] ?? 0.0).toDouble(),
      currentFeatures:
          (map['current_features'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }
}
