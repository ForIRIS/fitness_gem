import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise_config.dart';
import '../services/workout_model_service.dart';

/// RepCounter - ML 기반 Rep 카운팅 및 코칭 로직
class RepCounter {
  final ExerciseConfig config;
  final WorkoutModelService _modelService = WorkoutModelService();

  // 설정
  static const int _bufferSize = 30;
  static const double _inferenceThreshold = 0.7; // State 확정 임계값

  // 상태
  final List<List<List<double>>> _poseBuffer = [];
  int _repCount = 0;
  String? _currentState;
  bool _isProcessing = false;

  // 코칭 콜백
  void Function(String)? onCoachingMessage;

  RepCounter(this.config);

  /// 현재 Rep 카운트
  int get repCount => _repCount;

  /// 현재 상태
  String? get currentState => _currentState;

  /// 카운터 리셋
  void reset() {
    _repCount = 0;
    _poseBuffer.clear();
    _currentState = null;
    _isProcessing = false;
  }

  /// 포즈를 분석하여 Rep 카운트
  /// 반환값: 새로운 Rep이 카운트되었으면 true (비동기 분석 결과는 별도 처리)
  bool processFrame(Pose pose) {
    // 1. 포즈를 [33, 3] 리스트로 변환하여 버퍼에 추가
    final currentFrame = _poseToLandmarkList(pose);
    _poseBuffer.add(currentFrame);

    // 2. 버퍼가 30프레임이 되면 ML 추론 실행
    if (_poseBuffer.length >= _bufferSize) {
      if (!_isProcessing) {
        _runInference();
      }
      _poseBuffer.removeAt(0); // 슬라이딩 윈도우
    }

    return false; // Rep 증가는 _runInference 내부 상태 변화에서 감지됨
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

    // 1. 가장 높은 확률의 Phase 찾기
    int maxIdx = 0;
    double maxProb = 0.0;
    for (int i = 0; i < output.phaseProbs.length; i++) {
      if (output.phaseProbs[i] > maxProb) {
        maxProb = output.phaseProbs[i];
        maxIdx = i;
      }
    }

    final detectedState = labels[maxIdx];

    // 2. 상태 변화에 따른 Rep 카운팅
    if (maxProb >= _inferenceThreshold) {
      // terminal state (e.g., 'Ready' or 'Up' complete) 감지 로직
      // 예: '4_Right_Up' 또는 '7_Left_Up'에서 '1_Ready'로 돌아올 때 카운트
      if (_currentState != null && _currentState != detectedState) {
        if ((_currentState!.contains('Up') ||
                _currentState!.contains('Peak')) &&
            detectedState.contains('Ready')) {
          _repCount++;
        }
      }
      _currentState = detectedState;
    }

    // 3. 코칭 (공식 Deviation Score 기준)
    if (output.deviationScore > 0.6) {
      // 0.6 이상이면 자세 불안정으로 간주
      _triggerCoaching(detectedState);
    }
  }

  void _triggerCoaching(String state) {
    if (config.coachingCues == null) return;

    // 현재 state에 맞는 coaching cue 가져오기
    final cueMap = config.coachingCues![state];
    if (cueMap != null && cueMap is Map) {
      // 가장 대표적인 운동 가이드 (예: hip_knee_ankle_l) 추출
      // 실제로는 더 정밀한 매핑 로직이 필요할 수 있음
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
