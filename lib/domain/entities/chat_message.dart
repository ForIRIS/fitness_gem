import 'workout_curriculum.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;
  final WorkoutCurriculum? curriculum;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.curriculum,
  });
}
