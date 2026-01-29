import 'dart:async';
import '../services/tts_service.dart';

class CoachingMessage {
  final String message;
  final String? audioUrl;
  final DateTime timestamp;

  CoachingMessage({required this.message, this.audioUrl})
    : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachingMessage &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

class CoachingManagementService {
  static final CoachingManagementService _instance =
      CoachingManagementService._internal();
  factory CoachingManagementService() => _instance;
  CoachingManagementService._internal();

  final TTSService _ttsService = TTSService();

  // Streams for UI updates
  final _messageController = StreamController<CoachingMessage?>.broadcast();
  Stream<CoachingMessage?> get messageStream => _messageController.stream;

  // Configuration & State
  static const Duration globalCooling = Duration(seconds: 4);
  static const Duration duplicateCooling = Duration(seconds: 10);

  DateTime? _lastMessageTime;
  final Map<String, DateTime> _lastMessageMap = {};

  CoachingMessage? _currentVisibleMessage;

  /// Deliver a coaching message with frequency capping and prioritization
  Future<void> deliver(String message, {String? audioUrl}) async {
    final now = DateTime.now();

    // 1. Global Cooling Check
    if (_lastMessageTime != null &&
        now.difference(_lastMessageTime!) < globalCooling) {
      return;
    }

    // 2. Duplicate Prevention Check
    if (_lastMessageMap.containsKey(message)) {
      if (now.difference(_lastMessageMap[message]!) < duplicateCooling) {
        return;
      }
    }

    // Update state
    final coachingMessage = CoachingMessage(
      message: message,
      audioUrl: audioUrl,
    );
    _lastMessageTime = now;
    _lastMessageMap[message] = now;
    _currentVisibleMessage = coachingMessage;

    // 3. UI Notification
    _messageController.add(coachingMessage);

    // 4. Delivery Prioritization: Audio or TTS
    if (audioUrl != null && audioUrl.isNotEmpty) {
      // TODO: Implement Audio Player service if needed
      // For now, fallback to TTS as per current capabilities
      await _ttsService.speak(message);
    } else {
      await _ttsService.speak(message);
    }

    // Auto-clear message after 3 seconds (2s visible + 1s fade)
    // The widget will handle the transition, but we clear the logical state
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentVisibleMessage == coachingMessage) {
        _currentVisibleMessage = null;
        _messageController.add(null);
      }
    });
  }

  void dispose() {
    _messageController.close();
  }
}
