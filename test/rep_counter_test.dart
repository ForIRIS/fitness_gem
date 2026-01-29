import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_gem/models/exercise_config.dart';
import 'package:fitness_gem/utils/rep_counter.dart';
import 'package:fitness_gem/services/workout_model_service.dart';
import 'package:fitness_gem/models/exercise_config.dart'
    show ExerciseModelOutput;

class ManualMockWorkoutModelService implements WorkoutModelService {
  @override
  Future<ExerciseModelOutput?> runInference(
    List<List<List<double>>> poseSequence,
  ) async => null;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> loadModel(String modelPath) async => true;

  @override
  Future<bool> loadModelFromAsset(String assetPath) async => true;

  @override
  Future<bool> loadSampleModel() async => true;
}

void main() {
  group('RepCounter Sequential Mode', () {
    late RepCounter repCounter;
    late ManualMockWorkoutModelService mockModelService;
    late ExerciseConfig config;

    setUp(() {
      mockModelService = ManualMockWorkoutModelService();
      config = ExerciseConfig(
        id: 'test_seq',
        classLabels: {
          'classes': ['1_Ready', '2_Down', '3_Peak', '4_Up'],
          'num_classes': 4,
        },
      );
      repCounter = RepCounter(config, modelService: mockModelService);
    });

    test('should count a rep when sequence is followed correctly', () async {
      // Simulate following 1 -> 2 -> 3 -> 4 -> 1
      final sequence = ['1_Ready', '2_Down', '3_Peak', '4_Up', '1_Ready'];

      for (final state in sequence) {
        final probs = List.filled(4, 0.0);
        probs[['1_Ready', '2_Down', '3_Peak', '4_Up'].indexOf(state)] = 1.0;

        repCounter.handleModelOutputForTest(
          ExerciseModelOutput(
            phaseProbs: probs,
            deviationScore: 0.0,
            currentFeatures: [0.0],
          ),
        );
      }

      expect(repCounter.repCount, 1);
    });
  });
}
