import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise_config.dart';
import '../services/workout_model_service.dart';
import '../services/coaching_management_service.dart';
import 'pose_normalization.dart';
import 'adaptive_one_euro_filter.dart';
import '../models/counting_mode.dart';
import '../models/exercise_phase.dart';

/// RepCounter - ML-based rep counting and coaching logic
class RepCounter {
  final ExerciseConfig config;
  final WorkoutModelService _modelService;
  final CoachingManagementService _cms;
  final AdaptiveOneEuroFilter _smoothingFilter;

  // Settings
  static const int _bufferSize = 30;
  static const double _inferenceThreshold = 0.9; // 90% confidence

  // State
  final List<List<List<double>>> _poseBuffer = [];
  int _repCount = 0;
  String? _currentState;
  ExercisePhase? _currentPhase;
  bool _isProcessing = false;

  // Debouncing & Sequence
  String? _lastDetectedState;
  int _stateCounter = 0;
  static const int _debounceThreshold =
      2; // Must appear 2 detected frames in a row

  // Sequence Mode Tracking
  final Set<String> _detectedLabelsInRep = {};
  int _totalPhases = 0;
  final Set<String> _sidesCompletedInCycle = {};

  // Evaluation & Performance Analysis
  final List<List<double>> _featureBuffer = [];
  final Map<String, List<double>> _movingAverageFeatures = {};

  // Coaching callback (Consider deprecated in favor of CMS)
  void Function(String)? onCoachingMessage;

  // Rep Count Callback
  final void Function(int)? onRepCountChanged;

  RepCounter(
    this.config, {
    this.onRepCountChanged,
    WorkoutModelService? modelService,
    CoachingManagementService? coachingService,
  }) : _modelService = modelService ?? WorkoutModelService(),
       _cms = coachingService ?? CoachingManagementService(),
       _smoothingFilter = AdaptiveOneEuroFilter(
         profile: config.smoothingProfile,
         adaptive: true,
       ) {
    _initializeMode();
  }

  void _initializeMode() {
    if (config.classLabels == null) return;
    final labels = List<String>.from(config.classLabels!['classes'] ?? []);
    if (labels.isEmpty) return;

    // Phase count for sequential/side modes
    _totalPhases =
        config.numClasses ??
        labels.where((l) => RegExp(r'^\d').hasMatch(l)).length;
    if (_totalPhases == 0) _totalPhases = labels.length;
  }

  /// Current rep count
  int get repCount => _repCount;

  /// Current phase
  ExercisePhase? get currentPhase => _currentPhase;

  /// Current state

  String? get currentState => _currentState;

  /// Reset counter
  void reset() {
    _repCount = 0;
    _poseBuffer.clear();
    _currentState = null;
    _currentPhase = null;
    _isProcessing = false;

    _detectedLabelsInRep.clear();
    _featureBuffer.clear();
    _movingAverageFeatures.clear();
    _sidesCompletedInCycle.clear();
    _lastDetectedState = null;
    _stateCounter = 0;
  }

  /// Analyze pose and count reps
  void processFrame(Pose pose) {
    final rawFrame = _poseToLandmarkList(pose);

    // Apply temporal smoothing
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final flat = rawFrame.expand((l) => l).toList();
    final smoothedFlat = _smoothingFilter.filter(t, flat);

    // Reconstruct frame
    final List<List<double>> currentFrame = [];
    for (int i = 0; i < smoothedFlat.length; i += 3) {
      currentFrame.add([
        smoothedFlat[i],
        smoothedFlat[i + 1],
        smoothedFlat[i + 2],
      ]);
    }

    _poseBuffer.add(currentFrame);

    if (_poseBuffer.length >= _bufferSize) {
      if (!_isProcessing) {
        _runInference();
      }
      _poseBuffer.removeAt(0);
    }
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
        final detectedPhase = ExercisePhase.fromLabel(detectedState);
        if (_currentState != detectedState) {
          _onStateChange(detectedState);
          _currentState = detectedState;
          _currentPhase = detectedPhase;

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
    final mode = config.countType;

    switch (mode) {
      case CountingMode.singleAction:
        _handleActionTransition(newState);
        break;
      case CountingMode.alternatingFullCycle:
      case CountingMode.alternatingPerSide:
      case CountingMode.sequential:
        _handleSequentialTransition(newState);
        break;
    }
  }

  void _incrementRep() {
    _repCount++;
    onRepCountChanged?.call(_repCount);
  }

  /// Action Mode: Count specific actions
  void _handleActionTransition(String newState) {
    // Ignore utility states
    final phase = ExercisePhase.fromLabel(newState);
    if (phase == ExercisePhase.error ||
        phase == ExercisePhase.idle ||
        phase == ExercisePhase.ready) {
      return;
    }

    // Prepare debouncing or specific action logic if needed
    // For now, any distinct action state entry counts as a rep
    // assuming _onStateChange is already debounced by _debounceThreshold
    _incrementRep();
  }

  /// Sequential, Side & Alternating Modes
  void _handleSequentialTransition(String newState) {
    // Collect detected labels
    _detectedLabelsInRep.add(newState);

    // Check for sequence completion (Restart)
    // Convention: "1_Ready" or similar starts/resets the sequence
    final isRestart = newState.startsWith('1');

    if (isRestart && _detectedLabelsInRep.length >= 2) {
      // Check if rep should be counted
      if (_shouldCountSequentialRep()) {
        _processCompletion();
      } else if (_detectedLabelsInRep.any(
        (l) => ExercisePhase.fromLabel(l) == ExercisePhase.peak,
      )) {
        // Validation Error: If a "Peak" label is skipped

        _checkPeakSkip();
      }
      _detectedLabelsInRep.clear();
      _detectedLabelsInRep.add(newState);
    }
  }

  void _processCompletion() {
    final mode = config.countType;

    if (mode == CountingMode.alternatingFullCycle) {
      final side = _detectCompletedSide();
      if (side != null) {
        _sidesCompletedInCycle.add(side);
        if (_sidesCompletedInCycle.length >= 2) {
          _incrementRep();
          _sidesCompletedInCycle.clear();
        }
      }
    } else {
      // SEQUENTIAL or ALTERNATING_PER_SIDE
      _incrementRep();
    }
  }

  String? _detectCompletedSide() {
    if (_detectedLabelsInRep.any((l) => l.contains('Right'))) return 'R';
    if (_detectedLabelsInRep.any((l) => l.contains('Left'))) return 'L';
    return null;
  }

  bool _shouldCountSequentialRep() {
    if (_detectedLabelsInRep.isEmpty) return false;

    // 1. Ratio Check
    final numDetected = _detectedLabelsInRep.length;
    final ratio = numDetected / _totalPhases;
    // Lower threshold provided as we might skip some transition frames
    if (ratio < 0.5) return false;

    // 2. Peak Check
    final labels = List<String>.from(config.classLabels!['classes'] ?? []);
    final peakLabels = labels
        .where((l) => ExercisePhase.fromLabel(l) == ExercisePhase.peak)
        .toList();
    for (final peak in peakLabels) {
      // If we are in an alternating mode, we only care about the peak matching the declared side
      // for the current sequence.
      if (!_detectedLabelsInRep.contains(peak)) {
        final mode = config.countType;
        if (mode == CountingMode.alternatingFullCycle ||
            mode == CountingMode.alternatingPerSide) {
          continue;
        }
        return false;
      }
    }

    // 3. Side Consistency Check (for alternating modes)
    final mode = config.countType;
    if (mode == CountingMode.alternatingFullCycle ||
        mode == CountingMode.alternatingPerSide) {
      final hasRight = _detectedLabelsInRep.any((l) => l.contains('Right'));
      final hasLeft = _detectedLabelsInRep.any((l) => l.contains('Left'));

      // If we have mixed signals within a single sequence, invalid
      if (hasRight && hasLeft) return false;

      // Ensure we hit the peak for the detected side
      if (hasRight) {
        if (!peakLabels.any(
          (l) => l.contains('Right') && _detectedLabelsInRep.contains(l),
        )) {
          return false;
        }
      } else if (hasLeft) {
        if (!peakLabels.any(
          (l) => l.contains('Left') && _detectedLabelsInRep.contains(l),
        )) {
          return false;
        }
      } else {
        // No side detected? Valid only if SEQUENTIAL
        if (mode != CountingMode.sequential) return false;
      }
    }

    return true;
  }

  void _checkPeakSkip() {
    final labels = List<String>.from(config.classLabels!['classes'] ?? []);
    final peakLabels = labels
        .where((l) => ExercisePhase.fromLabel(l) == ExercisePhase.peak)
        .toList();
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

  /// Evaluation & Performance Analysis
  void _updatePerformanceStats(ExerciseModelOutput output, String state) {
    if (output.currentFeatures.isEmpty) return;

    // Buffer currentFeatures
    _featureBuffer.add(output.currentFeatures);

    // Maintain running average
    _calculateMovingAverage(state);

    // Single-Rep Sequence Analysis
    if (ExercisePhase.fromLabel(state) == ExercisePhase.peak) {
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
