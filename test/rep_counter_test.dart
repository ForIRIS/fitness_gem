import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_gem/domain/entities/exercise_config.dart';
import 'package:fitness_gem/utils/rep_counter.dart';
import 'package:fitness_gem/services/workout_model_service.dart';
import 'package:fitness_gem/domain/services/coaching_manager.dart';
import 'package:fitness_gem/domain/interfaces/feedback_output.dart';
import 'package:fitness_gem/models/exercise_model_output.dart';

class ManualMockWorkoutModelService implements WorkoutModelService {
  @override
  Future<ExerciseModelOutput?> runInference(
    List<List<List<double>>> poseSequence,
  ) async => null;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> loadModel(String modelPath) async => true;

  Future<bool> loadLocalBundle(String bundleId) async => true;
}

class MockFeedbackOutput implements FeedbackOutput {
  @override
  Future<void> speak(String message) async {}
}

class MockCoachingManager implements CoachingManager {
  @override
  Future<void> deliver(String message, {String? audioUrl}) async {}

  @override
  Future<void> deliverPositive(String message) async {}

  @override
  void dispose() {}

  @override
  Stream<CoachingMessage?> get messageStream => const Stream.empty();
}

void main() {
  late ManualMockWorkoutModelService mockModelService;
  late MockCoachingManager mockCoachingManager;

  setUp(() {
    mockModelService = ManualMockWorkoutModelService();
    mockCoachingManager = MockCoachingManager();
  });

  group('RepCounter SEQUENTIAL Mode', () {
    late RepCounter repCounter;
    // Labels matching the actual model format
    final classes = [
      '1_Ready',
      '2_Right_Down',
      '3_Right_Peak',
      '4_Right_Up',
      '5_Left_Down',
      '6_Left_Peak',
      '7_Left_Up',
    ];

    setUp(() {
      final config = ExerciseConfig(
        id: 'test_seq',
        classLabels: {
          'classes': classes,
          'num_classes': 7,
          'countingMode': 'SEQUENTIAL',
        },
      );
      repCounter = RepCounter(
        config,
        modelService: mockModelService,
        coachingManager: mockCoachingManager,
      );
    });

    test('should count a rep when full sequence (R + L) is completed', () {
      // Full cycle: Ready -> R_Down -> R_Peak -> R_Up -> L_Down -> L_Peak -> L_Up -> Ready
      final sequence = [
        '1_Ready',
        '2_Right_Down',
        '3_Right_Peak',
        '4_Right_Up',
        '5_Left_Down',
        '6_Left_Peak',
        '7_Left_Up',
        '1_Ready',
      ];
      _simulateSequence(repCounter, sequence, classes);
      expect(repCounter.repCount, 1);
    });
  });

  group('RepCounter SINGLE_ACTION Mode', () {
    late RepCounter repCounter;
    final classes = ['Idle', 'Jab', 'Cross', 'Hook'];

    setUp(() {
      final config = ExerciseConfig(
        id: 'test_action',
        classLabels: {'classes': classes, 'countingMode': 'SINGLE_ACTION'},
      );
      repCounter = RepCounter(
        config,
        modelService: mockModelService,
        coachingManager: mockCoachingManager,
      );
    });

    test('should count each action label', () {
      _simulateState(repCounter, 'Idle', classes.length, classes);
      _simulateState(repCounter, 'Jab', classes.length, classes); // 1
      _simulateState(repCounter, 'Idle', classes.length, classes);
      _simulateState(repCounter, 'Cross', classes.length, classes); // 2
      expect(repCounter.repCount, 2);
    });
  });

  group('RepCounter ALTERNATING_PER_SIDE Mode', () {
    late RepCounter repCounter;
    final classes = [
      '1_Ready',
      '2_Right_Down',
      '3_Right_Peak',
      '4_Right_Up',
      '5_Left_Down',
      '6_Left_Peak',
      '7_Left_Up',
    ];

    setUp(() {
      final config = ExerciseConfig(
        id: 'test_per_side',
        classLabels: {
          'classes': classes,
          'num_classes': 7,
          'countingMode': 'ALTERNATING_PER_SIDE',
        },
      );
      repCounter = RepCounter(
        config,
        modelService: mockModelService,
        coachingManager: mockCoachingManager,
      );
    });

    test('should count each side as a full rep', () {
      // Right side only: Ready -> R_Down -> R_Peak -> R_Up -> Ready
      _simulateSequence(repCounter, [
        '1_Ready',
        '2_Right_Down',
        '3_Right_Peak',
        '4_Right_Up',
        '1_Ready',
      ], classes);
      expect(repCounter.repCount, 1);
      // Left side only: L_Down -> L_Peak -> L_Up -> Ready
      _simulateSequence(repCounter, [
        '5_Left_Down',
        '6_Left_Peak',
        '7_Left_Up',
        '1_Ready',
      ], classes);
      expect(repCounter.repCount, 2);
    });
  });

  group('RepCounter ALTERNATING_FULL_CYCLE Mode', () {
    late RepCounter repCounter;
    final classes = [
      '1_Ready',
      '2_Right_Down',
      '3_Right_Peak',
      '4_Right_Up',
      '5_Left_Down',
      '6_Left_Peak',
      '7_Left_Up',
    ];

    setUp(() {
      final config = ExerciseConfig(
        id: 'test_full_cycle',
        classLabels: {
          'classes': classes,
          'num_classes': 7,
          'countingMode': 'ALTERNATING_FULL_CYCLE',
        },
      );
      repCounter = RepCounter(
        config,
        modelService: mockModelService,
        coachingManager: mockCoachingManager,
      );
    });

    test('should count only after both sides are completed', () {
      // Right side only: Ready -> R_Down -> R_Peak -> R_Up -> Ready
      _simulateSequence(repCounter, [
        '1_Ready',
        '2_Right_Down',
        '3_Right_Peak',
        '4_Right_Up',
        '1_Ready',
      ], classes);
      expect(repCounter.repCount, 0); // Not yet, waiting for Left
      // Left side: L_Down -> L_Peak -> L_Up -> Ready
      _simulateSequence(repCounter, [
        '5_Left_Down',
        '6_Left_Peak',
        '7_Left_Up',
        '1_Ready',
      ], classes);
      expect(repCounter.repCount, 1); // Now counted!
    });
  });
}

void _simulateSequence(
  RepCounter counter,
  List<String> sequence,
  List<String> labels,
) {
  for (final state in sequence) {
    _simulateState(counter, state, labels.length, labels);
  }
}

void _simulateState(
  RepCounter counter,
  String state,
  int numClasses,
  List<String> labels,
) {
  for (int i = 0; i < 3; i++) {
    final probs = List.filled(numClasses, 0.0);
    final idx = labels.indexOf(state);
    if (idx != -1) probs[idx] = 1.0;
    counter.handleModelOutputForTest(
      ExerciseModelOutput(
        phaseProbs: probs,
        deviationScore: 0.0,
        currentFeatures: [0.0],
      ),
    );
  }
}
