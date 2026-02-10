import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io'; // For File
import 'package:image_picker/image_picker.dart';
import '../core/di/injection.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/chat_message.dart';
import '../../presentation/controllers/ai_interview_controller.dart';
import 'widgets/ai/chat_message_bubble.dart';
import 'workout_detail_view.dart';

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        _controller.selectImage(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
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
                  itemCount: _controller.messages.length,
                  itemBuilder: (context, index) {
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
          // 1. Loading Text / Generating State
          if (_controller.isLoading) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null, // Disabled
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.generatingWorkout, // "Generating your curriculum..."
                      style: GoogleFonts.barlow(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 2. Completed State -> Navigation Button
          if (_controller.isInterviewComplete) {
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go Home
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.deepPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      "Finish",
                      style: GoogleFonts.barlow(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Workout
                      final lastMessage = _controller.messages.lastWhere(
                        (m) => m.curriculum != null,
                        orElse: () => ChatMessage(text: '', isUser: false),
                      );

                      if (lastMessage.curriculum != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutDetailView(
                              curriculum: lastMessage.curriculum!,
                            ),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Start Workout",
                      style: GoogleFonts.barlow(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // 3. Normal Input State
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Preview
              if (_controller.selectedImage != null)
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _controller.selectedImage!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: _controller.clearImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Colors.deepPurple,
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller.messageController,
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
                  GestureDetector(
                    onTap: () {
                      if (_controller.isListening) {
                        _controller.stopListening();
                      } else {
                        _controller.startListening(
                          onPermissionDenied: _onPermissionDenied,
                        );
                      }
                    },
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
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _controller.sendMessage(
                        _controller.messageController.text,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return ChatMessageBubble(
      message: message,
      maxWidth: MediaQuery.of(context).size.width * 0.8,
      userProfile: widget.userProfile,
      onAssessmentComplete: () => _controller.generateCurriculum(),
      onSkipAssessment: () => _controller.generateCurriculum(),
      onConfirmCurriculum: (curriculum) {
        // Navigate to WorkoutDetailView or perform action
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailView(curriculum: curriculum),
          ),
        );
      },
      onViewCurriculumDetail: (curriculum) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailView(curriculum: curriculum),
          ),
        );
      },
      onRetry: () => _controller.retryConnection(),
    );
  }
}
