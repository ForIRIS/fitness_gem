import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/workout_curriculum.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';

/// AIChatView - AI 상담 채팅 화면
class AIChatView extends StatefulWidget {
  final UserProfile userProfile;

  const AIChatView({super.key, required this.userProfile});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  WorkoutCurriculum? _suggestedCurriculum;

  @override
  void initState() {
    super.initState();
    // 초기 메시지
    _messages.add(
      ChatMessage(
        text:
            '안녕하세요! 오늘은 어떤 운동을 하고 싶으신가요?\n'
            '예: "가볍게 하체 운동 하고 싶어", "상체 위주로 해줘"',
        isUser: false,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();

    try {
      final firebaseService = FirebaseService();
      final geminiService = GeminiService();

      // 모든 운동 가져오기
      final allWorkouts = await firebaseService.fetchWorkoutAllList();

      // Gemini에 커리큘럼 요청
      final curriculum = await geminiService.chatForCurriculum(
        userMessage: message,
        profile: widget.userProfile,
        availableWorkouts: allWorkouts,
      );

      if (curriculum != null) {
        _suggestedCurriculum = curriculum;

        final responseText =
            '''
${curriculum.title}을 추천드립니다!

${curriculum.description}

포함된 운동:
${curriculum.workoutTaskList.map((t) => '• ${t.title} (${t.adjustedSets}세트 x ${t.adjustedReps}회)').join('\n')}

예상 소요 시간: 약 ${curriculum.estimatedMinutes}분

이 커리큘럼으로 진행하시겠습니까?''';

        setState(() {
          _messages.add(ChatMessage(text: responseText, isUser: false));
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              text: '죄송합니다, 커리큘럼을 생성하지 못했습니다. 다시 시도해주세요.',
              isUser: false,
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: '오류가 발생했습니다: $e', isUser: false));
        _isLoading = false;
      });
    }
  }

  void _confirmCurriculum() {
    if (_suggestedCurriculum != null) {
      Navigator.pop(context, _suggestedCurriculum);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('AI 상담', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 채팅 메시지 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildLoadingBubble();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // 확인 버튼 (커리큘럼 제안 시)
          if (_suggestedCurriculum != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmCurriculum,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('이 커리큘럼으로 진행'),
                    ),
                  ),
                ],
              ),
            ),

          // 입력 필드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(top: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[850],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.deepPurple,
                  iconSize: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.deepPurple : Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
            SizedBox(width: 12),
            Text('생각 중...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
