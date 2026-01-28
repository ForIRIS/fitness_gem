import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../models/workout_curriculum.dart';
import '../models/workout_task.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import 'workout_detail_view.dart';
import 'loading_view.dart';
import 'camera_view.dart';

/// AIChatView - AI Consultation Chat Screen
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
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Shimmer Animation Controller (Infinite Loop)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Initial Message
    _messages.add(
      ChatMessage(
        text:
            'Hello! What kind of workout would you like to do today?\n'
            'Example: "I want to do a light lower body workout", "Focus on my upper body"',
        isUser: false,
      ),
    );
  }

  // ... (Middle code omitted)

  // ... (Middle code omitted)

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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedImage == null) return;

    final imageToSend = _selectedImage;

    setState(() {
      _messages.add(
        ChatMessage(text: message, isUser: true, imagePath: imageToSend?.path),
      );
      _isLoading = true;
      _suggestedCurriculum = null;
      _selectedImage = null;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final geminiService = GeminiService();

      if (imageToSend != null) {
        final response = await geminiService.chatWithImage(
          imageFile: imageToSend,
          userMessage: message.isEmpty ? "이 사진에 대해 설명해줘" : message,
          profile: widget.userProfile,
        );

        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(text: response.message, isUser: false));
            _isLoading = false;
          });
        }
      } else {
        final firebaseService = FirebaseService();
        final allWorkouts = await firebaseService.fetchWorkoutAllList();

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
                text: AppLocalizations.of(
                  context,
                )!.curriculumRecommendation(curriculum.title),
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
                text: AppLocalizations.of(context)!.curriculumGenerationError,
                isUser: false,
              ),
            );
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: AppLocalizations.of(context)!.errorOccurred(e),
            isUser: false,
          ),
        );
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
    // Navigate to Resource Caching Screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingView(curriculum: curriculum),
      ),
    );

    // Navigate to Workout Screen upon caching completion
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
        title: Text(
          AppLocalizations.of(context)!.aiChat,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/fitness_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.black),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Chat Message List
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

              // Confirm Button (When Curriculum Suggested)
              if (_suggestedCurriculum != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirmCurriculum,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.replaceWithCurriculum,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Input Field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05), // Glassmorphism
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      Container(
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedImage = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.grey,
                          ),
                          onPressed: _pickImage,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.aiChatPlaceholder,
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
                            // Allow empty text when image is selected
                            onSubmitted: (_) {
                              if (_messageController.text.trim().isNotEmpty ||
                                  _selectedImage != null) {
                                _sendMessage();
                              }
                            },
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // Display as Card if message contains curriculum
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
          color: message.isUser
              ? Colors.deepPurple
              : Colors.white.withValues(alpha: 0.1), // Glassmorphism for AI
          borderRadius: BorderRadius.circular(16),
          border: message.isUser
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
            Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
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
                      Text(
                        AppLocalizations.of(context)!.aiConsultResult,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
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
                    'About ${curriculum.estimatedMinutes} min • ${curriculum.workoutTaskList.length} exercises',
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
                      label: Text(AppLocalizations.of(context)!.viewDetail),
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
                      label: Text(AppLocalizations.of(context)!.startNow),
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
              '${task.adjustedSets} Sets x ${task.adjustedReps} Reps',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer Effect Curriculum Loading Card
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
        // Create gradient movement effect using 0.0 ~ 1.0 value
        // When value changes 0 -> 1, gradient stops also move
        final value = _shimmerController.value;
        const double range = 0.5; // Gradient width

        // Move range: -range ~ 1.0 + range
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
                Colors.grey.shade600, // Bright part
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
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.curriculum,
    this.imagePath,
  });
}
