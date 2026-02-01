/// Interface for feedback output (e.g., TTS, Audio)
abstract class FeedbackOutput {
  /// Deliver a feedback message
  Future<void> speak(String message);
}
