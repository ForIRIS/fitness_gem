import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/workout_curriculum.dart';
import '../domain/entities/workout_task.dart';
import '../services/firebase_service.dart';
import '../../core/di/injection.dart';
import '../../domain/usecases/ai/chat_for_curriculum_usecase.dart';
import '../../domain/usecases/ai/chat_with_image_usecase.dart';
import 'workout_detail_view.dart';
import 'loading_view.dart';
import 'camera_view.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final TTSService _ttsService = TTSService();
  final STTService _sttService = STTService();

  bool _isTtsEnabled = true;
  bool _isListening = false;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Shimmer Animation Controller (Infinite Loop)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _initializeServices();

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

  Future<void> _initializeServices() async {
    await _ttsService.initialize();
    await _sttService.initialize();
  }

  Future<void> _startListening() async {
    final available = await _sttService.initialize();
    if (available) {
      setState(() => _isListening = true);
      _sttService.startListening(
        onResult: (text) {
          setState(() {
            _messageController.text = text;
          });
        },
        languageCode: Localizations.localeOf(context).languageCode == 'ko'
            ? 'ko-KR'
            : 'en-US',
      );
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _sttService.stopListening();
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
      if (imageToSend != null) {
        final chatWithImage = getIt<ChatWithImageUseCase>();
        final result = await chatWithImage.execute(
          ChatWithImageParams(
            userMessage: message.isEmpty ? "Describe this image" : message,
            imageFile: imageToSend,
            profile: widget.userProfile,
          ),
        );

        result.fold(
          (failure) {
            if (mounted) {
              setState(() {
                _messages.add(
                  ChatMessage(
                    text: AppLocalizations.of(
                      context,
                    )!.errorOccurred(failure.message ?? 'Unknown error'),
                    isUser: false,
                  ),
                );
                _isLoading = false;
              });
            }
          },
          (response) {
            if (mounted) {
              setState(() {
                _messages.add(
                  ChatMessage(text: response.message, isUser: false),
                );
                _isLoading = false;
              });
              if (_isTtsEnabled) {
                _ttsService.speak(response.message);
              }
            }
          },
        );
      } else {
        final firebaseService = FirebaseService();
        final allWorkouts = await firebaseService.fetchWorkoutAllList();

        final chatForCurriculum = getIt<ChatForCurriculumUseCase>();
        final result = await chatForCurriculum.execute(
          ChatForCurriculumParams(
            userMessage: message,
            profile: widget.userProfile,
            availableWorkouts: allWorkouts,
          ),
        );

        result.fold(
          (failure) {
            if (mounted) {
              setState(() {
                _messages.add(
                  ChatMessage(
                    text: AppLocalizations.of(
                      context,
                    )!.errorOccurred(failure.message),
                    isUser: false,
                  ),
                );
                _isLoading = false;
              });
            }
          },
          (curriculum) {
            if (mounted) {
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
                if (_isTtsEnabled) {
                  _ttsService.speak(
                    AppLocalizations.of(
                      context,
                    )!.curriculumRecommendation(curriculum.title),
                  );
                }
              } else {
                setState(() {
                  _messages.add(
                    ChatMessage(
                      text: AppLocalizations.of(
                        context,
                      )!.curriculumGenerationError,
                      isUser: false,
                    ),
                  );
                  _isLoading = false;
                });
              }
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: AppLocalizations.of(context)!.errorOccurred(e.toString()),
              isUser: false,
            ),
          );
          _isLoading = false;
        });
      }
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
      backgroundColor: const Color(0xFFF3E5F5), // Light purple/pink
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.aiChat,
          style: GoogleFonts.barlow(
            color: const Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
        actions: [
          IconButton(
            icon: Icon(
              _isTtsEnabled ? Icons.volume_up : Icons.volume_off,
              color: const Color(0xFF1A237E),
            ),
            onPressed: () {
              setState(() => _isTtsEnabled = !_isTtsEnabled);
              if (!_isTtsEnabled) _ttsService.stop();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE1BEE7), // Lighter Purple
                    Color(0xFFF3E5F5), // Base
                    Color(0xFFE3F2FD), // Light Blue tint
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5E35B1), Color(0xFF9575CD)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5E35B1).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _confirmCurriculum,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.replaceWithCurriculum,
                              style: GoogleFonts.barlow(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.05)),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
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
                            color: Colors.black54,
                          ),
                          onPressed: _pickImage,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: GoogleFonts.barlow(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.aiChatPlaceholder,
                              hintStyle: GoogleFonts.barlow(
                                color: Colors.black38,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
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
                        const SizedBox(width: 8),
                        // Voice Input Button
                        GestureDetector(
                          onLongPressStart: (_) => _startListening(),
                          onLongPressEnd: (_) => _stopListening(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening
                                  ? Colors.red
                                  : const Color(0xFF5E35B1),
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isLoading ? null : _sendMessage,
                          icon: const Icon(Icons.send),
                          color: const Color(0xFF5E35B1),
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
          color: message.isUser ? null : Colors.white,
          gradient: message.isUser
              ? const LinearGradient(
                  colors: [Color(0xFF5E35B1), Color(0xFF9575CD)],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E35B1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
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
                        style: GoogleFonts.barlow(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    curriculum.title,
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'About ${curriculum.estimatedMinutes} min • ${curriculum.workoutTasks.length} exercises',
                    style: GoogleFonts.barlow(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
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
                itemCount: curriculum.workoutTasks.length,
                itemBuilder: (context, index) {
                  return _buildMiniWorkoutCard(
                    curriculum.workoutTasks[index],
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
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5E35B1),
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.barlow(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: GoogleFonts.barlow(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${task.adjustedSets} Sets x ${task.adjustedReps} Reps',
              style: GoogleFonts.barlow(color: Colors.white70, fontSize: 11),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                Colors.grey.shade100,
                Colors.grey.shade50, // Bright part
                Colors.grey.shade100,
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
        color: Colors.grey.shade50,
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
  final String? imagePath;
  final WorkoutCurriculum? curriculum;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.curriculum,
  });
}
