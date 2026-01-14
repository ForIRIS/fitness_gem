import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:presentation_displays/display.dart';

/// DisplayService
/// 외부 디스플레이 연결 상태를 관리하고 데이터를 전송하는 서비스
class DisplayService {
  final DisplayManager _displayManager = DisplayManager();

  // 연결된 디스플레이 목록 스트림
  final StreamController<List<Display>> _displaysController =
      StreamController.broadcast();
  Stream<List<Display>> get displaysStream => _displaysController.stream;

  List<Display> _currentDisplays = [];
  Display? _activeDisplay;

  bool get isConnected => _activeDisplay != null;

  DisplayService() {
    _init();
  }

  Timer? _refreshTimer;

  void _init() {
    // 초기 디스플레이 목록 확인
    _refreshDisplays();

    // 2초마다 디스플레이 목록 갱신 (스트림 API 불확실성 대응)
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _refreshDisplays();
    });
  }

  void dispose() {
    _refreshTimer?.cancel();
    _displaysController.close();
  }

  Future<void> _refreshDisplays() async {
    try {
      final displays = await _displayManager.getDisplays();
      if (displays != null) {
        // 변화가 있을 때만 업데이트 (간단한 비교)
        final newIds = displays.map((d) => d.displayId).join();
        final currentIds = _currentDisplays.map((d) => d.displayId).join();

        if (_currentDisplays.length != displays.length ||
            newIds != currentIds) {
          debugPrint('Displays updated: ${displays.length} found');
          _currentDisplays = displays;
          _displaysController.add(displays);

          // 자동 연결 로직
          if (displays.isNotEmpty && _activeDisplay == null) {
            _connectToDisplay(displays.first);
          } else if (displays.isEmpty && _activeDisplay != null) {
            _disconnect();
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting displays: $e');
    }
  }

  Future<void> _connectToDisplay(Display display) async {
    if (display.displayId == null) return;

    try {
      await _displayManager.showSecondaryDisplay(
        displayId: display.displayId!,
        routerName: 'external_dashboard',
      );
      _activeDisplay = display;
      debugPrint('Connected to secondary display: ${display.displayId}');
    } catch (e) {
      debugPrint('Error connecting to display: $e');
    }
  }

  Future<void> _disconnect() async {
    _activeDisplay = null;
    debugPrint('Disconnected from secondary display');
  }

  /// 외부 디스플레이로 데이터 전송
  /// [data]는 JSON encodable이어야 함 (Map 등)
  Future<void> sendData(Map<String, dynamic> data) async {
    if (_activeDisplay == null) return;
    try {
      // presentation_displays는 기본적으로 transferDataToPresentation 메서드를 제공
      // 라이브러리 버전에 따라 메서드명이 다를 수 있으나
      // 1.0.0 기준 await _displayManager.transferDataToPresentation(data);
      await _displayManager.transferDataToPresentation(data);
    } catch (e) {
      // 빈번한 에러 로그 방지를 위해 debugPrint는 제한적으로 사용 권장
    }
  }
}
