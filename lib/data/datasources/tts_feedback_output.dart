import '../../domain/interfaces/feedback_output.dart';
import '../../services/tts_service.dart';

/// Data Source: Implementation of FeedbackOutput using TTSService
class TTSFeedbackOutput implements FeedbackOutput {
  final TTSService _ttsService;

  TTSFeedbackOutput({TTSService? ttsService})
    : _ttsService = ttsService ?? TTSService();

  @override
  Future<void> speak(String message) async {
    await _ttsService.speak(message);
  }
}
