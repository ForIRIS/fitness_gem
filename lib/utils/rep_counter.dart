import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise_config.dart';
import '../services/workout_model_service.dart';

/// RepCounter - ML-based rep counting and coaching logic
class RepCounter {
  final ExerciseConfig config;
  final WorkoutModelService _modelService = WorkoutModelService();

  // Settings
  static const int _bufferSize = 30;
  static const double _inferenceThreshold = 0.7; // State confirmation threshold

  // State
  final List<List<List<double>>> _poseBuffer = [];
  int _repCount = 0;
  String? _currentState;
  bool _isProcessing = false;

  // Coaching callback
  void Function(String)? onCoachingMessage;

  RepCounter(this.config);

  /// Current rep count
  int get repCount => _repCount;

  /// Current state
  String? get currentState => _currentState;

  /// Reset counter
  void reset() {
    _repCount = 0;
    _poseBuffer.clear();
    _currentState = null;
    _isProcessing = false;
  }

  /// Analyze pose and count reps
  /// Returns: true if a new rep was counted (async analysis results are handled separately)
  bool processFrame(Pose pose) {
    // 1. Convert pose to [33, 3] list and add to buffer
    final currentFrame = _poseToLandmarkList(pose);
    _poseBuffer.add(currentFrame);

    // 2. Run ML inference when buffer reaches 30 frames
    if (_poseBuffer.length >= _bufferSize) {
      if (!_isProcessing) {
        _runInference();
      }
      _poseBuffer.removeAt(0); // Sliding window
    }

    return false; // Rep increment is detected inside _runInference state changes
  }

  Future<void> _runInference() async {
    _isProcessing = true;
    try {
      final result = await _modelService.runInference(List.from(_poseBuffer));
      if (result != null) {
        _handleModelOutput(result);
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _handleModelOutput(ExerciseModelOutput output) {
    if (config.classLabels == null) return;

    final labels = List<String>.from(config.classLabels!['classes'] ?? []);
    if (labels.isEmpty || output.phaseProbs.length != labels.length) return;

    // 1. Find the phase with the highest probability
    int maxIdx = 0;
    double maxProb = 0.0;
    for (int i = 0; i < output.phaseProbs.length; i++) {
      if (output.phaseProbs[i] > maxProb) {
        maxProb = output.phaseProbs[i];
        maxIdx = i;
      }
    }

    final detectedState = labels[maxIdx];

    // 2. Count reps based on state changes
    if (maxProb >= _inferenceThreshold) {
      // Terminal state (e.g., 'Ready' or 'Up' complete) detection logic
      // Example: Count when transitioning from '4_Right_Up' or '7_Left_Up' back to '1_Ready'
      if (_currentState != null && _currentState != detectedState) {
        if ((_currentState!.contains('Up') ||
                _currentState!.contains('Peak')) &&
            detectedState.contains('Ready')) {
          _repCount++;
        }
      }
      _currentState = detectedState;
    }

    // 3. Coaching (based on official Deviation Score)
    if (output.deviationScore > 0.6) {
      // Consider posture unstable if score is above 0.6
      _triggerCoaching(detectedState);
    }
  }

  void _triggerCoaching(String state) {
    if (config.coachingCues == null) return;

    // Get coaching cue for the current state
    final cueMap = config.coachingCues![state];
    if (cueMap != null && cueMap is Map) {
      // Extract representative exercise guide (e.g., hip_knee_ankle_l)
      // Actual mapping logic could be more sophisticated
      final firstCue = cueMap.values.firstWhere(
        (v) => v['movement'] != null,
        orElse: () => null,
      );
      if (firstCue != null) {
        onCoachingMessage?.call(firstCue['movement']);
      }
    }
  }

  List<List<double>> _poseToLandmarkList(Pose pose) {
    final List<List<double>> landmarks = List.generate(
      33,
      (_) => [0.0, 0.0, 0.0],
    );

    pose.landmarks.forEach((type, landmark) {
      if (type.index < 33) {
        landmarks[type.index] = [landmark.x, landmark.y, landmark.z];
      }
    });

    return landmarks;
  }
}
