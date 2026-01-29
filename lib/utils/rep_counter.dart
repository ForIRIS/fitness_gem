import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise_config.dart';
import '../services/workout_model_service.dart';
import '../services/coaching_management_service.dart';
import 'pose_normalization.dart';

/// RepCounter - ML-based rep counting and coaching logic
class RepCounter {
  final ExerciseConfig config;
  final WorkoutModelService _modelService;
  final CoachingManagementService _cms = CoachingManagementService();

  // Settings
  static const int _bufferSize = 30;
  static const double _inferenceThreshold = 0.9; // 90% confidence

  // State
  final List<List<List<double>>> _poseBuffer = [];
  int _repCount = 0;
  String? _currentState;
  bool _isProcessing = false;

  // Debouncing & Sequence
  String? _lastDetectedState;
  int _stateCounter = 0;
  static const int _debounceThreshold =
      2; // Must appear 2 detected frames in a row

  // Sequence Mode Tracking
  final Set<String> _detectedLabelsInRep = {};
  bool _isSequentialMode = false;
  int _totalPhases = 0;

  // Non-Sequential Mode Tracking
  String? _lastLockedLabel;
  String? _nonSeqPendingLabel;

  // Evaluation & Performance Analysis
  final List<List<double>> _featureBuffer = [];
  final Map<String, List<double>> _movingAverageFeatures = {};

  // Coaching callback (Consider deprecated in favor of CMS)
  void Function(String)? onCoachingMessage;

  RepCounter(this.config, {WorkoutModelService? modelService})
    : _modelService = modelService ?? WorkoutModelService() {
    _initializeMode();
  }

  void _initializeMode() {
    if (config.classLabels == null) return;
    final labels = List<String>.from(config.classLabels!['classes'] ?? []);
    if (labels.isEmpty) return;

    // Trigger: If labels are numerical, the system operates in Sequence Mode.
    _isSequentialMode = labels.any((l) => RegExp(r'^\d').hasMatch(l));
    _totalPhases = labels.length;
  }

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
    _detectedLabelsInRep.clear();
    _featureBuffer.clear();
    _movingAverageFeatures.clear();
    _lastLockedLabel = null;
    _nonSeqPendingLabel = null;
    _lastDetectedState = null;
    _stateCounter = 0;
  }

  /// Analyze pose and count reps
  bool processFrame(Pose pose) {
    final currentFrame = _poseToLandmarkList(pose);
    _poseBuffer.add(currentFrame);

    if (_poseBuffer.length >= _bufferSize) {
      if (!_isProcessing) {
        _runInference();
      }
      _poseBuffer.removeAt(0);
    }

    return false;
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

  @visibleForTesting
  void handleModelOutputForTest(ExerciseModelOutput output) {
    _handleModelOutput(output);
  }

  void _handleModelOutput(ExerciseModelOutput output) {
    if (config.classLabels == null) return;

    final labels = List<String>.from(config.classLabels!['classes'] ?? []);
    if (labels.isEmpty || output.phaseProbs.length != labels.length) return;

    int maxIdx = 0;
    double maxProb = 0.0;
    for (int i = 0; i < output.phaseProbs.length; i++) {
      if (output.phaseProbs[i] > maxProb) {
        maxProb = output.phaseProbs[i];
        maxIdx = i;
      }
    }

    final detectedState = labels[maxIdx];

    // Debouncing
    if (maxProb >= _inferenceThreshold) {
      if (_lastDetectedState == detectedState) {
        _stateCounter++;
      } else {
        _lastDetectedState = detectedState;
        _stateCounter = 1;
      }

      if (_stateCounter >= _debounceThreshold) {
        if (_currentState != detectedState) {
          _onStateChange(detectedState);
          _currentState = detectedState;

          // Reset feature buffer on label change
          _featureBuffer.clear();
        } else {
          // Same state: Evaluation & Performance
          _updatePerformanceStats(output, detectedState);
        }
      }
    } else {
      _stateCounter = 0;
      _lastDetectedState = null;
    }
  }

  void _onStateChange(String newState) {
    if (_isSequentialMode) {
      _handleSequentialTransition(newState);
    } else {
      _handleNonSequentialTransition(newState);
    }
  }

  /// Sequential Mode (Numerical Labels)
  void _handleSequentialTransition(String newState) {
    // Collect detected labels
    _detectedLabelsInRep.add(newState);

    // Rep Completion Check (Typical reset to "1_Ready" or similar)
    // assuming first label is start of sequence
    final isRestart = newState.startsWith('1');

    if (isRestart && _detectedLabelsInRep.length >= 2) {
      // Check if rep should be counted
      if (_shouldCountSequentialRep()) {
        _repCount++;
      } else if (_detectedLabelsInRep.any((l) => l.contains('Peak'))) {
        // Validation Error: If a "Peak" label is skipped
        _checkPeakSkip();
      }
      _detectedLabelsInRep.clear();
      _detectedLabelsInRep.add(newState);
    }
  }

  bool _shouldCountSequentialRep() {
    if (_detectedLabelsInRep.isEmpty) return false;

    // 1. At least 80% of the defined sequence numbers are detected.
    final numDetected = _detectedLabelsInRep.length;
    final ratio = numDetected / _totalPhases;
    if (ratio < 0.8) return false;

    // 2. All labels marked as "Peak" are successfully included in the sequence.
    final labels = List<String>.from(config.classLabels!['classes'] ?? []);
    final peakLabels = labels.where((l) => l.contains('Peak')).toList();
    for (final peak in peakLabels) {
      if (!_detectedLabelsInRep.contains(peak)) return false;
    }

    return true;
  }

  void _checkPeakSkip() {
    final labels = List<String>.from(config.classLabels!['classes'] ?? []);
    final peakLabels = labels.where((l) => l.contains('Peak')).toList();
    bool peakSkipped = false;
    for (final peak in peakLabels) {
      if (!_detectedLabelsInRep.contains(peak)) {
        peakSkipped = true;
        break;
      }
    }

    if (peakSkipped) {
      _cms.deliver("Please follow the on-screen guide accurately.");
    }
  }

  /// Non-Sequential Mode (Standard Labels)
  void _handleNonSequentialTransition(String newState) {
    // Trigger: count a rep when a label (not starting with Ready, Idle, or Error)
    // appears twice consecutively.
    if (newState.startsWith('Ready') ||
        newState.startsWith('Idle') ||
        newState.startsWith('Error')) {
      return;
    }

    if (_lastLockedLabel == newState) {
      // Already counted this label, waiting for a transition to reset
      return;
    }

    if (_nonSeqPendingLabel == newState) {
      // Consecutive appearance confirmed
      _repCount++;
      _lastLockedLabel = newState;
      _nonSeqPendingLabel = null;
    } else {
      _nonSeqPendingLabel = newState;
    }
  }

  /// Evaluation & Performance Analysis
  void _updatePerformanceStats(ExerciseModelOutput output, String state) {
    if (output.currentFeatures.isEmpty) return;

    // Buffer currentFeatures
    _featureBuffer.add(output.currentFeatures);

    // Maintain running average
    _calculateMovingAverage(state);

    // Single-Rep Sequence Analysis
    if (state.contains('Peak')) {
      _analyzePeakPerformance(output, state);
    }
  }

  void _calculateMovingAverage(String state) {
    if (_featureBuffer.isEmpty) return;

    final numFeatures = _featureBuffer.first.length;
    final List<double> averages = List.filled(numFeatures, 0.0);

    for (final frame in _featureBuffer) {
      for (int i = 0; i < numFeatures; i++) {
        averages[i] += frame[i];
      }
    }

    for (int i = 0; i < numFeatures; i++) {
      averages[i] /= _featureBuffer.length;
    }

    _movingAverageFeatures[state] = averages;
  }

  void _analyzePeakPerformance(ExerciseModelOutput output, String state) {
    // Monitor for significant confidence drops or deviations
    if (output.deviationScore > 0.6) {
      _triggerSpecificCoaching(state);
    }

    // Compare against median values
    if (config.medianStats != null && config.medianStats![state] != null) {
      // TODO: Detailed feature comparison logic
      // If error margin correlates with a specific model_cue
    }
  }

  void _triggerSpecificCoaching(String state) {
    if (config.coachingCues == null) return;

    final cues = config.coachingCues![state];
    if (cues != null && cues is Map) {
      // Find the first cue with a message
      for (final entry in cues.entries) {
        final cueData = entry.value;
        if (cueData is Map && cueData.containsKey('movement')) {
          _cms.deliver(cueData['movement']);
          return;
        }
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
    return PoseNormalization.normalizeByTorso(landmarks);
  }
}
