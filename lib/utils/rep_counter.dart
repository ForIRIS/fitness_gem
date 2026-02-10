import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../domain/entities/exercise_config.dart';
import '../services/workout_model_service.dart';
import '../domain/services/coaching_manager.dart';
import '../models/exercise_model_output.dart';
import 'pose_normalization.dart';
import 'adaptive_one_euro_filter.dart';
import '../models/counting_mode.dart';
import '../models/exercise_phase.dart';

/// RepCounter - ML-based rep counting and coaching logic
class RepCounter {
  final ExerciseConfig config;
  final WorkoutModelService _modelService;
  final CoachingManager _coachingManager;
  final AdaptiveOneEuroFilter _smoothingFilter;

  // Settings
  // Buffer size is now dynamic via config.windowSize
  static const double _inferenceThreshold = 0.9; // 90% confidence

  // State
  final List<List<List<double>>> _poseBuffer = [];
  int _repCount = 0;
  String? _currentState;
  ExercisePhase? _currentPhase;
  double _currentStability = 1.0;
  double _lastMaxProb = 0.0; // Expose probability

  // 60Hz Interpolation State
  static const double _targetHz = 60.0;
  List<List<double>>? _prevFrame;
  double _prevFrameTime = 0.0; // seconds (epoch-based)

  // Low confidence / Error tracking
  int _lowConfidenceCounter = 0;
  static const int _lowConfidenceThreshold = 10; // Frames

  // Debouncing & Sequence
  String? _lastDetectedState;
  int _stateCounter = 0;
  static const int _debounceThreshold =
      2; // Must appear 2 detected frames in a row

  // Sequence Mode Tracking
  final Set<String> _detectedLabelsInRep = {};
  int _totalPhases = 0;
  final Set<String> _sidesCompletedInCycle = {};
  int _goodRepStreak = 0;

  // Duration Mode Tracking
  double _cumulativeDuration = 0.0;
  DateTime? _lastInferenceTime;
  DateTime? _lastLogTime; // For throttle logging

  // Evaluation & Performance Analysis
  final List<List<double>> _featureBuffer = [];
  final Map<String, List<double>> _movingAverageFeatures = {};

  // Coaching callback (Consider deprecated in favor of CoachingManager)
  void Function(String)? onCoachingMessage;

  // Rep Count Callback
  final void Function(int)? onRepCountChanged;

  RepCounter(
    this.config, {
    this.onRepCountChanged,
    WorkoutModelService? modelService,
    required CoachingManager coachingManager,
  }) : _modelService = modelService ?? WorkoutModelService(),
       _coachingManager = coachingManager,
       _smoothingFilter = AdaptiveOneEuroFilter(
         profile: config.smoothingProfile,
         adaptive: true,
       ) {
    _initializeMode();
  }

  /// Initialize the model (async)
  Future<bool> initialize() async {
    final bundleId = config.id;
    debugPrint("RepCounter: Initializing model for bundleId: $bundleId");
    try {
      final success = await _modelService.loadLocalBundle(bundleId);
      if (success) {
        debugPrint("RepCounter: Model loaded successfully.");
      } else {
        debugPrint("RepCounter: Failed to load model bundle.");
      }
      return success;
    } catch (e) {
      debugPrint("RepCounter: Exception loading model: $e");
      return false;
    }
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

  /// Current form stability (1.0 = perfect, 0.0 = total deviation)
  double get currentStability => _currentStability;

  /// Reset counter
  void reset() {
    _repCount = 0;
    _poseBuffer.clear();
    _currentState = null;
    _currentPhase = null;
    _prevFrame = null;
    _prevFrameTime = 0.0;

    _detectedLabelsInRep.clear();
    _featureBuffer.clear();
    _movingAverageFeatures.clear();
    _sidesCompletedInCycle.clear();
    _lastDetectedState = null;
    _stateCounter = 0;
  }

  /// Analyze pose and count reps (with 60Hz interpolation)
  void processFrame(Pose pose) {
    final rawFrame = _poseToLandmarkList(pose);

    // Separate xyz from visibility for smoothing
    final dims = config.landmarkDimensions;
    final List<double> xyzFlat = [];
    final List<double> visibilities = [];
    for (final lm in rawFrame) {
      xyzFlat.addAll([lm[0], lm[1], lm[2]]);
      visibilities.add(lm.length > 3 ? lm[3] : 1.0);
    }

    // Apply temporal smoothing (only on xyz, not visibility)
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final smoothedXyz = _smoothingFilter.filter(now, xyzFlat);

    // Reconstruct frame with correct number of values per landmark
    final List<List<double>> currentFrame = [];
    for (int i = 0; i < 33; i++) {
      final lm = [
        smoothedXyz[i * 3],
        smoothedXyz[i * 3 + 1],
        smoothedXyz[i * 3 + 2],
      ];
      if (dims >= 4) {
        lm.add(visibilities[i]);
      }
      currentFrame.add(lm);
    }

    // 60Hz Interpolation: fill gaps between camera frames
    if (_prevFrame != null && _prevFrameTime > 0) {
      final elapsed = now - _prevFrameTime;

      // How many 60Hz ticks fit in this gap?
      final expectedFrames = (elapsed * _targetHz).round();

      if (expectedFrames > 1) {
        // Interpolate intermediate frames (skip first = prev, last = current)
        for (int f = 1; f < expectedFrames; f++) {
          final t = f / expectedFrames; // 0.0 → 1.0
          final interpolated = _lerpFrame(_prevFrame!, currentFrame, t);
          _addFrameToBuffer(interpolated);
        }
      }
    }

    // Add the real current frame
    _addFrameToBuffer(currentFrame);

    // Save for next interpolation
    _prevFrame = currentFrame;
    _prevFrameTime = now;
  }

  /// Add a single frame to buffer and trigger inference if ready
  void _addFrameToBuffer(List<List<double>> frame) {
    _poseBuffer.add(frame);

    if (_poseBuffer.length >= config.windowSize) {
      _runInference(List.from(_poseBuffer));
      _poseBuffer.removeAt(0);
    }
  }

  /// Linearly interpolate between two landmark frames
  List<List<double>> _lerpFrame(
    List<List<double>> a,
    List<List<double>> b,
    double t,
  ) {
    final result = <List<double>>[];
    for (int i = 0; i < a.length; i++) {
      final lm = <double>[];
      for (int j = 0; j < a[i].length; j++) {
        lm.add(a[i][j] + (b[i][j] - a[i][j]) * t);
      }
      result.add(lm);
    }
    return result;
  }

  Future<void> _runInference(List<List<List<double>>> bufferSnapshot) async {
    try {
      final result = await _modelService.runInference(bufferSnapshot);
      if (result != null) {
        _handleModelOutput(result);
      }
    } catch (e) {
      debugPrint('Inference error: $e');
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

    _lastMaxProb = maxProb; // Store for external access

    final detectedState = labels[maxIdx];

    // 1. Error Monitoring Phase (Run on every result)
    _monitorPoseErrors(output, detectedState, maxProb);

    // Debouncing
    if (maxProb >= _inferenceThreshold) {
      // Reset low confidence counter since we have a good lock
      _lowConfidenceCounter = 0;

      if (_lastDetectedState == detectedState) {
        _stateCounter++;
      } else {
        _lastDetectedState = detectedState;
        _stateCounter = 1;
      }

      if (_stateCounter >= _debounceThreshold) {
        final detectedPhase = ExercisePhase.fromLabel(
          detectedState,
          classPhases: config.classPhases,
        );
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
      // Low confidence / Weird pose handling
      _lowConfidenceCounter++;
      if (_lowConfidenceCounter >= _lowConfidenceThreshold) {
        // If the model is persistently confused, it's likely a form issue
        _onLowConfidence();
        _lowConfidenceCounter = 0; // Reset to avoid spamming every frame
      }

      _stateCounter = 0;
      _lastDetectedState = null;
    }

    // Continuous Logic (Duration Mode)
    if (config.countType == CountingMode.duration) {
      _handleDurationCounting(detectedState, maxProb);
    }

    // Debug Logging (Throttled to ~1 second)
    final now = DateTime.now();
    if (_lastLogTime == null || now.difference(_lastLogTime!).inSeconds >= 1) {
      _lastLogTime = now;
      debugPrint(
        'Pose Analysis: State=$detectedState, Conf=${(maxProb * 100).toStringAsFixed(1)}%, Stability=${(_currentStability * 100).toStringAsFixed(1)}%',
      );
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
      case CountingMode.duration:
        // Duration handled continuously in _handleModelOutput
        break;
    }
  }

  void _incrementRep() {
    _repCount++;
    onRepCountChanged?.call(_repCount);

    // Positive Feedback Check
    if (_currentStability >= 0.85) {
      _goodRepStreak++;
      if (_goodRepStreak >= 3) {
        // Trigger cheer
        final cheers = [
          "Great job!",
          "Perfect form!",
          "Keep it up!",
          "Looking strong!",
          "Excellent!",
        ];
        // Simple random selection
        final message = cheers[_repCount % cheers.length];
        _coachingManager.deliverPositive(message);
        _goodRepStreak = 0; // Reset or keep counting? Reset to pace it out.
      }
    } else {
      _goodRepStreak = 0;
    }
  }

  /// Action Mode: Count specific actions
  void _handleActionTransition(String newState) {
    // Ignore utility states
    final phase = ExercisePhase.fromLabel(
      newState,
      classPhases: config.classPhases,
    );
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
    // Collect detected labels in current sequence
    _detectedLabelsInRep.add(newState);

    // Check for sequence completion (Restart/Ready state)
    // We count when returning to the starting position ('Ready' or '1_...')
    final phase = ExercisePhase.fromLabel(
      newState,
      classPhases: config.classPhases,
    );
    final isRestart = newState.startsWith('1') || phase == ExercisePhase.ready;

    if (isRestart && _detectedLabelsInRep.length >= 2) {
      // Check if rep should be counted (all phases visited)
      if (_shouldCountSequentialRep()) {
        _processCompletion();
      } else if (_detectedLabelsInRep.any(
        (l) =>
            ExercisePhase.fromLabel(l, classPhases: config.classPhases) ==
            ExercisePhase.peak,
      )) {
        // Validation Error: If a "Peak" label exists in config but was skipped
        _checkPeakSkip();
      }
      // Start fresh for the next rep
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

    // 2. Peak Check / Sequence Completeness Check
    final labels = List<String>.from(config.classLabels!['classes'] ?? []);
    final peakLabels = labels
        .where(
          (l) =>
              ExercisePhase.fromLabel(l, classPhases: config.classPhases) ==
              ExercisePhase.peak,
        )
        .toList();

    final isSingleAction = config.countType == CountingMode.singleAction;

    if (peakLabels.isEmpty && !isSingleAction) {
      // Strict Sequence Check for Non-Peak Exercises:
      // Ensure we visited all uniquely numbered phases defined in the config.
      final numericPrefixesInConfig = labels
          .map((l) => l.split('_').first)
          .where((s) => int.tryParse(s) != null)
          .toSet();

      if (numericPrefixesInConfig.isNotEmpty) {
        final detectedPrefixes = _detectedLabelsInRep
            .map((l) => l.split('_').first)
            .where((s) => int.tryParse(s) != null)
            .toSet();

        // If we missed any numeric phase that exists in the config, it's an incomplete rep
        if (detectedPrefixes.length < numericPrefixesInConfig.length) {
          return false;
        }
      } else {
        // Fallback for non-numeric labels: Ensure at least one non-ready/non-idle phase was hit
        final hasMovement = _detectedLabelsInRep.any((l) {
          final p = ExercisePhase.fromLabel(l, classPhases: config.classPhases);
          return p == ExercisePhase.movement;
        });
        if (!hasMovement) return false;
      }
    } else {
      // Peak Check: Ensure the peak state was hit during this sequence
      for (final peak in peakLabels) {
        // If we are in an alternating mode, we only care about the peak matching the declared side
        if (!_detectedLabelsInRep.contains(peak)) {
          final mode = config.countType;
          if (mode == CountingMode.alternatingFullCycle ||
              mode == CountingMode.alternatingPerSide) {
            continue;
          }
          return false;
        }
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
        .where(
          (l) =>
              ExercisePhase.fromLabel(l, classPhases: config.classPhases) ==
              ExercisePhase.peak,
        )
        .toList();
    bool peakSkipped = false;

    for (final peak in peakLabels) {
      if (!_detectedLabelsInRep.contains(peak)) {
        peakSkipped = true;
        break;
      }
    }

    if (peakSkipped) {
      _coachingManager.deliver("Please follow the on-screen guide accurately.");
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
    // We can now analyze performance in any phase if we have stats
    _analyzePoseQuality(output, state);
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

  /// Monitor for generic deviations or low confidence signals
  void _monitorPoseErrors(
    ExerciseModelOutput output,
    String state,
    double probability,
  ) {
    // If deviation score is very high, strictly warn
    if (output.deviationScore > 0.8) {
      _coachingManager.deliver(
        "Movement looks uncertain. Please check your form.",
      );
    }
  }

  void _onLowConfidence() {
    // Triggered when model has low confidence for multiple frames
    _coachingManager.deliver("Please adjust your position or camera angle.");
  }

  void _handleDurationCounting(String detectedState, double probability) {
    final now = DateTime.now();
    if (_lastInferenceTime == null) {
      _lastInferenceTime = now;
      return;
    }

    final dt = now.difference(_lastInferenceTime!).inMilliseconds / 1000.0;
    _lastInferenceTime = now;

    // 1. Validate Target Phase
    // Using config.triggerPhase (e.g. "PEAK" or "3_Plank")
    final trigger = config.triggerPhase;
    if (trigger == null) return;

    final isTargetPhase = detectedState.contains(trigger);

    // 2. Validate Confidence
    if (isTargetPhase && probability > _inferenceThreshold) {
      _cumulativeDuration += dt;

      // Increment rep for every 1.0 second accumulated
      while (_cumulativeDuration >= 1.0) {
        _incrementRep();
        _cumulativeDuration -= 1.0;
      }
    }
  }

  void _analyzePoseQuality(ExerciseModelOutput output, String state) {
    if (config.medianStats == null || config.classLabels == null) return;
    final statsData = config.medianStats![state];
    if (statsData == null) {
      _currentStability = 1.0;
      return;
    }

    List<double> medians;
    List<double>? stdDevs;

    // Parse Stats (Map or List)
    if (statsData is Map) {
      medians = List<double>.from(statsData['features'] ?? []);
      stdDevs = List<double>.from(statsData['stdDev'] ?? []);
    } else if (statsData is List) {
      medians = List<double>.from(statsData);
    } else {
      _currentStability = 1.0;
      return;
    }

    if (medians.isEmpty || medians.length != output.currentFeatures.length) {
      _currentStability = 1.0;
      return;
    }

    // Identify deviating features
    final featureKeys = config.featureKeys;
    if (featureKeys.length != medians.length) return;

    final deviatingFeatures = <String>{};
    double totalDeviation = 0.0;

    for (int i = 0; i < medians.length; i++) {
      final currentVal = output.currentFeatures[i];
      final medianVal = medians[i];
      final diff = (currentVal - medianVal).abs();

      // Normalize deviation by sigma if available
      double deviation;
      if (stdDevs != null && i < stdDevs.length && stdDevs[i] > 0.001) {
        deviation =
            (diff / stdDevs[i]).clamp(0.0, 5.0) /
            5.0; // Max 5 sigma = 100% deviation
      } else {
        deviation = diff.clamp(0.0, 0.5) / 0.5; // Fixed 0.5 threshold
      }

      totalDeviation += deviation;

      if (deviation > 0.4) {
        // Equivalent to ~2.0 sigma
        deviatingFeatures.add(featureKeys[i]);
      }
    }

    // Update real-time stability score
    _currentStability = (1.0 - (totalDeviation / medians.length)).clamp(
      0.0,
      1.0,
    );

    if (deviatingFeatures.isNotEmpty) {
      _triggerSpecificCoaching(state, deviatingFeatures);
    }
  }

  void _triggerSpecificCoaching(String state, Set<String> deviatingFeatures) {
    if (config.coachingCues == null) return;

    final cuesData = config.coachingCues![state];
    if (cuesData == null) return;

    // Handle List<dynamic> format from JSON
    if (cuesData is List) {
      for (final cueObj in cuesData) {
        if (cueObj is Map && cueObj.containsKey('feature')) {
          final targetFeatures = List<String>.from(cueObj['feature'] ?? []);
          // If any of the cue's target features are deviating, trigger it
          if (targetFeatures.any((f) => deviatingFeatures.contains(f))) {
            if (cueObj.containsKey('message')) {
              _coachingManager.deliver(cueObj['message']);
              return; // Deliver one message at a time
            }
          }
        }
      }
    }
    // Fallback for Map format (if legacy)
    else if (cuesData is Map) {
      for (final entry in cuesData.entries) {
        final cueData = entry.value;
        if (cueData is Map && cueData.containsKey('movement')) {
          // This legacy path doesn't check features? Preserving old behavior just in case
          // or we can remove it if we are sure. Let's keep it safe.
          _coachingManager.deliver(cueData['movement']);
          return;
        }
      }
    }
  }

  List<List<double>> _poseToLandmarkList(Pose pose) {
    final dims = config.landmarkDimensions;
    final List<List<double>> landmarks = List.generate(
      33,
      (_) => List.filled(dims, 0.0),
    );
    pose.landmarks.forEach((type, landmark) {
      if (type.index < 33) {
        final lm = [landmark.x, landmark.y, landmark.z];
        if (dims >= 4) lm.add(landmark.likelihood);
        landmarks[type.index] = lm;
      }
    });
    return PoseNormalization.normalizeByTorso(landmarks);
  }

  /// Check if the specific class is detected with high confidence
  bool isClassDetected(String className, {double threshold = 0.8}) {
    if (config.classLabels == null) return false;
    final labels = List<String>.from(config.classLabels!['classes'] ?? []);

    // Find index of label containing className
    // E.g. "0_Ready", "Ready"
    int index = -1;
    for (int i = 0; i < labels.length; i++) {
      if (labels[i].toLowerCase().contains(className.toLowerCase())) {
        index = i;
        break;
      }
    }

    if (index == -1 || currentState == null) return false;

    if (currentState!.toLowerCase().contains(className.toLowerCase())) {
      return _lastMaxProb >= threshold;
    }

    return false;
  }
}
