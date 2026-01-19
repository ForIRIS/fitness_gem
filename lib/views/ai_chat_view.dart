import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/workout_curriculum.dart';
import '../models/workout_task.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import 'workout_detail_view.dart';
import 'loading_view.dart';
import 'camera_view.dart';

/// AIChatView - AI 상담 채팅 화면
class AIChatView extends StatefulWidget {
  final UserProfile userProfile;

  const AIChatView({super.key, required this.userProfile});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  WorkoutCurriculum? _suggestedCurriculum;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Shimmer 애니메이션 컨트롤러 (무한 반복)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

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

  // ... (중간 코드 생략)

  // ... (중간 코드 생략)

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
      _suggestedCurriculum = null;
    });
    _messageController.clear();
    _scrollToBottom();

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

        setState(() {
          _messages.add(
            ChatMessage(
              text: '${curriculum.title}을 추천드립니다!',
              isUser: false,
              curriculum: curriculum,
            ),
          );
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
    _scrollToBottom();
  }

  void _confirmCurriculum() {
    if (_suggestedCurriculum != null) {
      Navigator.pop(context, _suggestedCurriculum);
    }
  }

  void _viewCurriculumDetail(WorkoutCurriculum curriculum) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailView(curriculum: curriculum),
      ),
    );
  }

  void _startWorkout(WorkoutCurriculum curriculum) async {
    // 리소스 캐싱 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingView(curriculum: curriculum),
      ),
    );

    // 캐싱 완료 시 운동 화면으로 이동
    if (result == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CameraView(curriculum: curriculum),
        ),
      );
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
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildShimmerCurriculumCard();
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
                      child: const Text('이 커리큘럼으로 교체'),
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
    // 커리큘럼이 포함된 메시지인 경우 카드 형태로 표시
    if (message.curriculum != null) {
      return _buildCurriculumCard(message);
    }

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

  Widget _buildCurriculumCard(ChatMessage message) {
    final curriculum = message.curriculum!;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI 추천 커리큘럼',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    curriculum.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '약 ${curriculum.estimatedMinutes}분 • ${curriculum.workoutTaskList.length}개 운동',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Workout Mini Cards (Horizontal Scroll)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: curriculum.workoutTaskList.length,
                itemBuilder: (context, index) {
                  return _buildMiniWorkoutCard(
                    curriculum.workoutTaskList[index],
                    index,
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewCurriculumDetail(curriculum),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('상세 보기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startWorkout(curriculum),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('바로 시작'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniWorkoutCard(WorkoutTask task, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${task.adjustedSets}세트 x ${task.adjustedReps}회',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer 효과의 커리큘럼 로딩 카드
  Widget _buildShimmerCurriculumCard() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Shimmer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 120, height: 16),
                  const SizedBox(height: 12),
                  _buildShimmerBox(width: 180, height: 20),
                  const SizedBox(height: 8),
                  _buildShimmerBox(width: 140, height: 14),
                ],
              ),
            ),

            // Mini Cards Shimmer
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return _buildShimmerMiniCard();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Buttons Shimmer
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(child: _buildShimmerBox(height: 44)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShimmerBox(height: 44)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({double? width, required double height}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        // 0.0 ~ 1.0 값을 이용해 그라디언트 이동 효과 생성
        // value가 0 -> 1로 변할 때 그라디언트의 stops도 이동
        final value = _shimmerController.value;
        const double range = 0.5; // 그라디언트 폭

        // 이동 범위: -range ~ 1.0 + range
        final offset = (value * (1 + range * 2)) - range;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade800,
                Colors.grey.shade600, // 밝은 부분
                Colors.grey.shade800,
              ],
              stops: [
                (offset - 0.1).clamp(0.0, 1.0),
                offset.clamp(0.0, 1.0),
                (offset + 0.1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerMiniCard() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShimmerBox(width: 24, height: 20),
            const SizedBox(height: 8),
            _buildShimmerBox(width: 80, height: 14),
            const SizedBox(height: 4),
            _buildShimmerBox(width: 60, height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final WorkoutCurriculum? curriculum;

  ChatMessage({required this.text, required this.isUser, this.curriculum});
}
