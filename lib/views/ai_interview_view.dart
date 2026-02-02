import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../domain/entities/user_profile.dart';
import '../../core/di/injection.dart';
import '../../domain/usecases/ai/start_interview_usecase.dart';
import '../../domain/usecases/ai/send_interview_message_usecase.dart';
import '../../domain/usecases/ai/generate_curriculum_from_interview_usecase.dart';
import '../../domain/usecases/workout/save_curriculum.dart';
// import '../../domain/entities/workout_curriculum.dart'; // Unused
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../services/firebase_service.dart';

import 'package:google_fonts/google_fonts.dart';
import 'home_view.dart' as home;

/// AIInterviewView - AI Interview Chat Screen
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
  // final GeminiService _geminiService = GeminiService(); // Removed
  final TTSService _ttsService = TTSService();
  final STTService _sttService = STTService();

  bool _isLoading = false;
  bool _isInterviewComplete = false;
  bool _hasError = false;
  bool _isTtsEnabled = true;
  bool _isListening = false;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _initializeServices();
    _startInterview();
  }

  Future<void> _initializeServices() async {
    await _ttsService.initialize();
    await _sttService.initialize();
  }

  Future<void> _startInterview() async {
    setState(() => _isLoading = true);

    try {
      final startInterview = getIt<StartInterviewUseCase>();
      final result = await startInterview.execute(widget.userProfile);

      String? response;
      result.fold(
        (failure) => debugPrint('Start interview failed: ${failure.message}'),
        (r) => response = r,
      );

      if (!mounted) return;

      if (response != null) {
        final nonNullResponse = response!;
        setState(() {
          _messages.add(_ChatMessage(text: nonNullResponse, isUser: false));
          _isLoading = false;
        });
        if (_isTtsEnabled) {
          _ttsService.speak(nonNullResponse);
        }
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

    final sendMessage = getIt<SendInterviewMessageUseCase>();
    final result = await sendMessage.execute(message);

    if (!mounted) return;

    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      },
      (response) async {
        if (!mounted) return;

        if (response.hasError) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          return;
        }

        // Remove JSON part from message and display
        String displayMessage = response.message;
        if (response.isComplete) {
          // Remove JSON part
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

        if (_isTtsEnabled && !response.isComplete) {
          _ttsService.speak(displayMessage);
        } else if (response.isComplete) {
          _ttsService.speak(AppLocalizations.of(context)!.downloadComplete);
        }

        // Update profile when interview is complete
        if (response.isComplete) {
          // Show generating message (can be handled by UI state or message)
          setState(() {
            _messages.add(
              _ChatMessage(
                text: 'Generating your personalized curriculum...',
                isUser: false,
              ),
            );
            _isLoading = true;
          });

          await _processInterviewResult(
            response.summaryText,
            response.extractedDetails,
          );
        }
      },
    );
    _scrollToBottom();
  }

  Future<void> _processInterviewResult(
    String? summaryText,
    Map<String, String>? extractedDetails,
  ) async {
    // Note: Profile saving not supported with immutable entities
    // The profile updates would need to be handled through a repository/use case
    // For now, we'll skip profile persistence and just generate the curriculum
    debugPrint('Interview complete - Summary: $summaryText');
    debugPrint('Extracted details: $extractedDetails');

    // TODO: Implement profile update through repository when available
    // final profile = widget.userProfile;
    // profile.interviewSummary = summaryText;
    // profile.extractedDetails = extractedDetails;
    // profile.lastInterviewDate = DateTime.now();
    // await UserProfile.saveProfile(profile);

    // 2. Generate Curriculum
    if (extractedDetails != null) {
      try {
        final firebaseService = FirebaseService();
        await firebaseService.initialize();
        final allWorkouts = await firebaseService.fetchWorkoutAllList();

        final generateCurriculum =
            getIt<GenerateCurriculumFromInterviewUseCase>();

        final result = await generateCurriculum.execute(
          GenerateCurriculumFromInterviewParams(
            profile: widget.userProfile,
            availableWorkouts: allWorkouts,
            interviewDetails: extractedDetails,
          ),
        );

        // Handling the result type Either<Failure, WorkoutCurriculum?>
        // We need to extract the curriculum from the Right side
        final curriculum = result.fold((failure) => null, (c) => c);

        if (curriculum != null) {
          // Save the curriculum using the use case
          try {
            final saveCurriculum = getIt<SaveCurriculumUseCase>();
            await saveCurriculum.execute(curriculum);

            if (mounted) {
              setState(() {
                _messages.add(
                  _ChatMessage(
                    text: 'Curriculum created: ${curriculum.title}',
                    isUser: false,
                  ),
                );
                _isLoading = false;
                _isInterviewComplete = true; // Use this to show "Start" button
              });

              if (mounted) {
                _ttsService.speak(
                  AppLocalizations.of(context)!.downloadComplete,
                );
              }
              return;
            }
          } catch (e) {
            debugPrint('Error saving curriculum: $e');
            // Continue to show error or fallback
          }
        }
      } catch (e) {
        debugPrint('Error generating curriculum in view: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isInterviewComplete = true;
      });
    }
  }

  void _skipInterview() {
    // _geminiService.endInterviewSession(); // No-op, removed
    if (widget.isFromOnboarding) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const home.HomeView()),
        (route) => false,
      );
    } else {
      Navigator.pop(context, false); // false = Interview skipped
    }
  }

  void _completeInterview() {
    // _geminiService.endInterviewSession(); // No-op, removed
    if (widget.isFromOnboarding) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const home.HomeView()),
        (route) => false,
      );
    } else {
      Navigator.pop(context, true); // true = Interview complete
    }
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
      backgroundColor: const Color(0xFFF3E5F5), // Light purple/pink
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AI Consultant',
          style: GoogleFonts.barlow(
            color: const Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _skipInterview,
        ),
        actions: [
          TextButton(
            onPressed: _skipInterview,
            child: Text(
              AppLocalizations.of(context)!.skip,
              style: GoogleFonts.barlow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
              // Guidance Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: const Color(0xFFFFF8E1), // Light Amber
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isFromOnboarding
                            ? AppLocalizations.of(context)!.aiConsultantBanner
                            : AppLocalizations.of(
                                context,
                              )!.aiProfileAnalysisBanner,
                        style: GoogleFonts.barlow(
                          color: Colors.amber[900],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Error Banner
              if (_hasError)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFFFEBEE), // Light Red
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A network error occurred',
                          style: GoogleFonts.barlow(
                            color: Colors.red[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _retryConnection,
                        child: Text(
                          AppLocalizations.of(context)!.retry,
                          style: GoogleFonts.barlow(
                            color: Colors.red[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Chat Message List
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

              // Completion Button (When Interview Complete)
              if (_isInterviewComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
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
                      child: ElevatedButton.icon(
                        onPressed: _completeInterview,
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          AppLocalizations.of(context)!.completeAndStart,
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Input Field
              if (!_isInterviewComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: GoogleFonts.barlow(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.answerPlaceholder,
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
                          onSubmitted: (_) => _sendMessage(),
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
                ),
            ],
          ),
        ],
      ),
    );
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _shimmerController.dispose();
    // _geminiService.endInterviewSession(); // No-op, removed
    super.dispose();
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
