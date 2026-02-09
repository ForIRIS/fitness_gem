import 'workout_curriculum.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;
  final WorkoutCurriculum? curriculum;
  final bool isError;
  final bool isLoading;
  final bool isAssessmentInvite;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.curriculum,
    this.isError = false,
    this.isLoading = false,
    this.isAssessmentInvite = false,
  });
}
