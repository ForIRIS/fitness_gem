import 'dart:async';
import '../interfaces/feedback_output.dart';

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

/// Domain Service: Manages coaching feedback logic (cooling, prioritization)
class CoachingManager {
  final FeedbackOutput _feedbackOutput;

  CoachingManager(this._feedbackOutput);

  // Streams for UI updates
  final _messageController = StreamController<CoachingMessage?>.broadcast();
  Stream<CoachingMessage?> get messageStream => _messageController.stream;

  // Configuration & State
  static const Duration globalCooling = Duration(seconds: 4);
  static const Duration defaultDuplicateCooling = Duration(seconds: 5);

  // Message-specific cooling durations
  static final Map<String, Duration> _specificCoolingDurations = {
    'Show your full body': const Duration(seconds: 15),
    'Lower your hips': const Duration(seconds: 8),
    'Keep your back straight': const Duration(seconds: 8),
  };

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
      final coolingDuration = _specificCoolingDurations.entries
          .firstWhere(
            (entry) => message.contains(entry.key),
            orElse: () => MapEntry(message, defaultDuplicateCooling),
          )
          .value;

      if (now.difference(_lastMessageMap[message]!) < coolingDuration) {
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
    // Currently only TTS is supported via FeedbackOutput
    await _feedbackOutput.speak(message);

    // Auto-clear message after 3 seconds (2s visible + 1s fade)
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
