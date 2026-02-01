/// Interview Response Entity
class InterviewResponse {
  final String message;
  final bool isComplete;
  final String? summaryText;
  final Map<String, String>? extractedDetails;
  final bool hasError;

  InterviewResponse({
    required this.message,
    required this.isComplete,
    this.summaryText,
    this.extractedDetails,
    this.hasError = false,
  });
}
