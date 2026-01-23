import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';

/// AIInterviewView - AI 인터뷰 채팅 화면
class AIInterviewView extends StatefulWidget {
  final UserProfile userProfile;
  final bool isFromOnboarding;

  const AIInterviewView({
    super.key,
    required this.userProfile,
    this.isFromOnboarding = true,
  });

  @override
  State<AIInterviewView> createState() => _AIInterviewViewState();
}

class _AIInterviewViewState extends State<AIInterviewView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final GeminiService _geminiService = GeminiService();

  bool _isLoading = false;
  bool _isInterviewComplete = false;
  bool _hasError = false;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startInterview();
  }

  Future<void> _startInterview() async {
    setState(() => _isLoading = true);

    try {
      final response = await _geminiService.startInterviewChat(
        widget.userProfile,
      );

      if (response != null) {
        setState(() {
          _messages.add(_ChatMessage(text: response, isUser: false));
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

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
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));
      _isLoading = true;
      _hasError = false;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _geminiService.sendInterviewMessage(message);

      if (response.hasError) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      // 메시지에서 JSON 부분 제거하고 표시
      String displayMessage = response.message;
      if (response.isComplete) {
        // JSON 부분 제거
        displayMessage = displayMessage
            .replaceAll(RegExp(r'```json[\s\S]*```', multiLine: true), '')
            .replaceAll(
              RegExp(
                r'\{[\s\S]*"interview_complete"[\s\S]*\}',
                multiLine: true,
              ),
              '',
            )
            .trim();
        if (displayMessage.isEmpty) {
          displayMessage = AppLocalizations.of(context)!.downloadComplete;
        }
      }

      setState(() {
        _messages.add(_ChatMessage(text: displayMessage, isUser: false));
        _isLoading = false;
        _isInterviewComplete = response.isComplete;
      });

      // 인터뷰 완료 시 프로필 업데이트
      if (response.isComplete) {
        await _saveInterviewResult(
          response.summaryText,
          response.extractedDetails,
        );
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _saveInterviewResult(
    String? summaryText,
    Map<String, String>? extractedDetails,
  ) async {
    final profile = widget.userProfile;
    profile.interviewSummary = summaryText;
    profile.extractedDetails = extractedDetails;
    profile.lastInterviewDate = DateTime.now();
    await UserProfile.saveProfile(profile);
  }

  void _skipInterview() {
    _geminiService.endInterviewSession();
    Navigator.pop(context, false); // false = 인터뷰 스킵됨
  }

  void _completeInterview() {
    _geminiService.endInterviewSession();
    Navigator.pop(context, true); // true = 인터뷰 완료됨
  }

  void _retryConnection() {
    setState(() {
      _hasError = false;
    });

    // If empty, start fresh
    if (_messages.isEmpty) {
      _startInterview();
      return;
    }

    // If last message was from user, retry sending it
    if (_messages.isNotEmpty && _messages.last.isUser) {
      final lastMessage = _messages.last.text;

      // Remove the last message from UI to avoid duplication when _sendMessage adds it back
      setState(() {
        _messages.removeLast();
        _messageController.text = lastMessage;
      });

      _sendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'AI Consultant',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _skipInterview,
        ),
        actions: [
          TextButton(
            onPressed: _skipInterview,
            child: Text(
              AppLocalizations.of(context)!.skip,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 안내 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.amber.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isFromOnboarding
                        ? AppLocalizations.of(context)!.aiConsultantBanner
                        : AppLocalizations.of(context)!.aiProfileAnalysisBanner,
                    style: const TextStyle(color: Colors.amber, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // 에러 배너
          if (_hasError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withValues(alpha: 0.2),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '네트워크 오류가 발생했습니다',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _retryConnection,
                    child: Text(
                      AppLocalizations.of(context)!.retry,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // 채팅 메시지 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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

          // 완료 버튼 (인터뷰 완료 시)
          if (_isInterviewComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completeInterview,
                  icon: const Icon(Icons.check_circle),
                  label: Text(AppLocalizations.of(context)!.completeAndStart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

          // 입력 필드
          if (!_isInterviewComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(top: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.answerPlaceholder,
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
                    color: Colors.amber,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final offset = (_shimmerController.value + (2 - index) * 0.15) % 1.0;
        final opacity = (1 - (offset * 2 - 1).abs()).clamp(0.3, 1.0);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _shimmerController.dispose();
    _geminiService.endInterviewSession();
    super.dispose();
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
