import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/workout_curriculum.dart';
// workout_task import removed
import '../services/firebase_service.dart';

import '../../core/di/injection.dart';
import '../../domain/usecases/ai/chat_for_curriculum_usecase.dart';
import '../../domain/usecases/ai/chat_with_image_usecase.dart';
import 'workout_detail_view.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/chat_message.dart';
import 'widgets/ai/chat_message_bubble.dart';
import 'widgets/ai/shimmer_curriculum_card.dart';

/// AIChatView - AI Consultation Chat Screen
class AIChatView extends StatefulWidget {
  final UserProfile userProfile;

  const AIChatView({super.key, required this.userProfile});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> {
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
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _initializeServices();
    // ... (rest of initState logic)

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
    final languageCode = Localizations.localeOf(context).languageCode;
    final available = await _sttService.initialize();
    if (available) {
      if (!mounted) return;
      setState(() => _isListening = true);
      _sttService.startListening(
        onResult: (text) {
          if (mounted) {
            setState(() {
              _messageController.text = text;
            });
          }
        },
        languageCode: languageCode == 'ko' ? 'ko-KR' : 'en-US',
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
        _hasInput = true; // Image counts as input
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

  void _confirmCurriculum([WorkoutCurriculum? curriculum]) {
    final targetCurriculum = curriculum ?? _suggestedCurriculum;
    if (targetCurriculum != null) {
      Navigator.pop(context, targetCurriculum);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No curriculum selected to replace')),
      );
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
                      return const ShimmerCurriculumCard();
                    }
                    return ChatMessageBubble(
                      message: _messages[index],
                      onConfirmCurriculum: _confirmCurriculum,
                      onViewCurriculumDetail: _viewCurriculumDetail,
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    );
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
                                color: const Color(
                                  0xFF5E35B1,
                                ).withValues(alpha: 0.3),
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
                margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5E35B1).withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
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
                                    onTap: () {
                                      setState(() {
                                        _selectedImage = null;
                                        _hasInput = _messageController.text
                                            .trim()
                                            .isNotEmpty;
                                      });
                                    },
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
                            color: Color(0xFF5E35B1), // Make icon active color
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
                            // Update state on every change to ensure button visibility
                            onChanged: (text) {
                              setState(() {
                                _hasInput = text.trim().isNotEmpty;
                              });
                            },
                            onSubmitted: (_) {
                              if (_hasInput || _selectedImage != null) {
                                _sendMessage();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Dynamic Button: Mic or Send
                        if (!_hasInput && _selectedImage == null)
                          // Voice Input Button (Show only when no input)
                          GestureDetector(
                            onLongPressStart: (_) => _startListening(),
                            onLongPressEnd: (_) => _stopListening(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? Colors.red.withValues(alpha: 0.1)
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
                          )
                        else
                          // Send Button (Show only when input exists)
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

  void _onTextChanged() {
    setState(() {
      _hasInput = _messageController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
