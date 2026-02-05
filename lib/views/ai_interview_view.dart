import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'onboarding/baseline_assessment_view.dart'; // Added import

import '../core/di/injection.dart';
import '../domain/entities/user_profile.dart';
import '../presentation/controllers/ai_interview_controller.dart'
    hide ChatMessage;
import '../presentation/controllers/ai_interview_controller.dart'
    as controller_model;
// To avoid conflict with local simplified usage or alias,
// though we will use the controller's model directly.
// Ideally, ChatMessage should be in a model file.
// For now, I will use controller_model.ChatMessage.

class AIInterviewView extends StatefulWidget {
  final UserProfile userProfile;

  const AIInterviewView({super.key, required this.userProfile});

  @override
  State<AIInterviewView> createState() => _AIInterviewViewState();
}

class _AIInterviewViewState extends State<AIInterviewView>
    with SingleTickerProviderStateMixin {
  late final AIInterviewController _controller;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _controller = getIt<AIInterviewController>();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Initialize controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.initialize(
          widget.userProfile,
          AppLocalizations.of(context)!,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shimmerController.dispose();
    // Do NOT dispose _controller here if it's a singleton/factory that might be reused?
    // It is registered as a factory, so we own this instance.
    // However, ChangeNotifier doesn't always need disposal if garbage collected, but better to be safe if it holds streams.
    // Our controller holds TextEditingController and Service references.
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onPermissionDenied() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.permissionRequired),
        content: Text(AppLocalizations.of(context)!.micPermissionReason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(AppLocalizations.of(context)!.openSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.aiConsulting,
          style: GoogleFonts.barlow(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return IconButton(
                icon: Icon(
                  _controller.isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                  color: _controller.isTtsEnabled
                      ? Colors.deepPurple
                      : Colors.grey,
                ),
                onPressed: _controller.toggleTts,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Scroll to bottom when messages change
                // Note: simple check like length comparison might be better than doing it every build.
                // But AnimatedBuilder triggers on notifyListeners.
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                if (_controller.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.networkError,
                        ), // Ensure this string exists or use fallback
                        ElevatedButton(
                          onPressed: _controller.retryConnection,
                          child: Text(l10n.retry), // Ensure string exists
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount:
                      _controller.messages.length +
                      (_controller.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _controller.messages.length) {
                      return _buildLoadingBubble();
                    }
                    final message = _controller.messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          _buildInputArea(l10n),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 16,
        right: 16,
        top: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller.messageController,
                  enabled:
                      !_controller.isLoading &&
                      !_controller.isInterviewComplete,
                  decoration: InputDecoration(
                    hintText: _controller.isListening
                        ? l10n.listening
                        : l10n.typeMessageHint,
                    hintStyle: GoogleFonts.barlow(
                      color: _controller.isListening
                          ? Colors.deepPurpleAccent
                          : Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _controller.sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              if (!_controller.isInterviewComplete) ...[
                // Mic Button
                GestureDetector(
                  onLongPress: () => _controller.startListening(
                    onPermissionDenied: _onPermissionDenied,
                  ),
                  onLongPressUp: _controller.stopListening,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _controller.isListening
                          ? Colors.redAccent
                          : Colors.deepPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _controller.isListening ? Icons.mic : Icons.mic_none,
                      color: _controller.isListening
                          ? Colors.white
                          : Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _controller.isLoading
                        ? null
                        : () => _controller.sendMessage(
                            _controller.messageController.text,
                          ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(controller_model.ChatMessage message) {
    if (message.isCard) {
      if (message.cardWidget != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: message.cardWidget!,
        );
      }
      // Fallback or specific handling for system generated card signals
      // Since Controller logic just added a blank "isCard: true" message for the curriculum:
      return _buildAssessmentRecommendation(context);
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
        child: _buildParsedText(message.text, isUser: message.isUser),
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

  // Reused from original but optimized
  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
            color: const Color(0xFF5E35B1).withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  // This was previously part of the view, keeping it as valid UI logic
  Widget _buildAssessmentRecommendation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assessmentRecommended, // "Physical Assessment Recommended"
                      style: GoogleFonts.barlow(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      l10n.assessmentRecommendedDesc, // "Let's check your form level."
                      style: GoogleFonts.barlow(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigation to Assessment
                // Using named route or direct push
                // Assuming BaselineAssessmentView is in the onboarding folder or main views
                // We need to import it if we push directly.
                // For now, I will use Navigator.pushNamed if possible or import it.
                // The original code used Navigator.push(MaterialPageRoute(builder: (_) => BaselineAssessmentView(userProfile: widget.userProfile)));
                // I need to import BaselineAssessmentView.
                // Let's add that import!
                _navigateToAssessment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(l10n.aiInviteAssessmentButton),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BaselineAssessmentView(userProfile: widget.userProfile),
      ),
    );
  }
}
