import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/workout_curriculum.dart';
import 'curriculum_card.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(WorkoutCurriculum) onConfirmCurriculum;
  final Function(WorkoutCurriculum) onViewCurriculumDetail;
  final VoidCallback? onRetry;
  final double maxWidth;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.onConfirmCurriculum,
    required this.onViewCurriculumDetail,
    this.onRetry,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Display as Card if message contains curriculum
    if (message.curriculum != null) {
      return CurriculumCard(
        curriculum: message.curriculum!,
        onConfirm: onConfirmCurriculum,
        onViewDetail: onViewCurriculumDetail,
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: message.isUser ? null : Colors.white,
          gradient: message.isUser
              ? const LinearGradient(
                  colors: [Color(0xFF5E35B1), Color(0xFF9575CD)],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: message.isUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(message.imagePath!),
                    height: 150,
                    width: 200, // Limit width for better look in bubble
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            _buildParsedText(message.text, isUser: message.isUser),
            if (message.isError && onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Retry",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedText(String text, {required bool isUser}) {
    final List<TextSpan> spans = [];
    final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final Match match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: GoogleFonts.barlow(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: GoogleFonts.barlow(
            color: isUser ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w800, // Extra bold for visibility
            height: 1.4,
          ),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: GoogleFonts.barlow(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
