import 'package:flutter/foundation.dart';
import '../services/display_service.dart';

class DisplayViewModel extends ChangeNotifier {
  final DisplayService _displayService = DisplayService();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  DisplayViewModel() {
    _init();
  }

  void _init() {
    _displayService.displaysStream.listen((displays) {
      final connected = displays.isNotEmpty;
      if (_isConnected != connected) {
        _isConnected = connected;
        notifyListeners();

        if (connected) {
          debugPrint("External Display Connected! Dual Screen Mode Active.");
        }
      }
    });
  }

  /// 운동 데이터 업데이트 및 외부 디스플레이 전송
  void updateSessionData({
    required String exerciseName,
    required int reps,
    required String feedback,
    required bool isGoodPose,
  }) {
    if (!_isConnected) return;

    final data = {
      'exercise': exerciseName,
      'reps': reps,
      'feedback': feedback,
      'isGoodPose': isGoodPose,
    };

    _displayService.sendData(data);
  }

  @override
  void dispose() {
    _displayService.dispose();
    super.dispose();
  }
}
