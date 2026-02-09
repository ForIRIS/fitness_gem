import 'package:flutter/widgets.dart'; // For TextEditingController
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../../l10n/app_localizations.dart';
import '../../core/di/injection.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/ai/start_interview_usecase.dart';
import '../../domain/usecases/ai/send_interview_message_usecase.dart';
import '../../domain/usecases/ai/generate_curriculum_from_interview_usecase.dart';
import '../../domain/usecases/workout/save_curriculum.dart';
import '../../services/tts_service.dart';
import '../../services/stt_service.dart';
import '../../services/firebase_service.dart';
import '../../services/gemini_cache_manager.dart';

import '../../domain/entities/chat_message.dart';

class AIInterviewController extends ChangeNotifier {
  final StartInterviewUseCase _startInterviewUseCase;
  final SendInterviewMessageUseCase _sendInterviewMessageUseCase;
  final GenerateCurriculumFromInterviewUseCase _generateCurriculumUseCase;
  final SaveCurriculumUseCase _saveCurriculumUseCase;
  final TTSService _ttsService;
  final STTService _sttService;
  final GeminiCacheManager _cacheManager;

  // State
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInterviewComplete = false;
  bool get isInterviewComplete => _isInterviewComplete;

  bool _hasError = false;
  bool get hasError => _hasError;

  bool _isTtsEnabled = true;
  bool get isTtsEnabled => _isTtsEnabled;

  bool _isListening = false;
  bool get isListening => _isListening;

  final TextEditingController messageController = TextEditingController();

  UserProfile? _userProfile;
  AppLocalizations? _l10n;
  Map<String, String>? _lastInterviewDetails;

  UserProfile? get userProfile => _userProfile;

  AIInterviewController({
    StartInterviewUseCase? startInterviewUseCase,
    SendInterviewMessageUseCase? sendInterviewMessageUseCase,
    GenerateCurriculumFromInterviewUseCase? generateCurriculumUseCase,
    SaveCurriculumUseCase? saveCurriculumUseCase,
    TTSService? ttsService,
    STTService? sttService,
    GeminiCacheManager? cacheManager,
  }) : _startInterviewUseCase =
           startInterviewUseCase ?? getIt<StartInterviewUseCase>(),
       _sendInterviewMessageUseCase =
           sendInterviewMessageUseCase ?? getIt<SendInterviewMessageUseCase>(),
       _generateCurriculumUseCase =
           generateCurriculumUseCase ??
           getIt<GenerateCurriculumFromInterviewUseCase>(),
       _saveCurriculumUseCase =
           saveCurriculumUseCase ?? getIt<SaveCurriculumUseCase>(),
       _ttsService = ttsService ?? getIt<TTSService>(),
       _sttService = sttService ?? getIt<STTService>(),
       _cacheManager = cacheManager ?? getIt<GeminiCacheManager>();

  Future<void> initialize(UserProfile profile, AppLocalizations l10n) async {
    _userProfile = profile;
    _l10n = l10n;
    await _ttsService.initialize();
    _ttsService.updateLocalizations(l10n);
    await _sttService.initialize();
    await _startInterview();
  }

  void toggleTts() {
    _isTtsEnabled = !_isTtsEnabled;
    if (!_isTtsEnabled) _ttsService.stop();
    notifyListeners();
  }

  Future<void> _startInterview() async {
    if (_userProfile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _startInterviewUseCase.execute(_userProfile!);

      result.fold(
        (failure) {
          debugPrint('Start interview failed: ${failure.message}');
          _hasError = true;
          _isLoading = false;
        },
        (response) {
          if (response != null) {
            _messages.add(ChatMessage(text: response, isUser: false));
            _isLoading = false;
            if (_isTtsEnabled) {
              _ttsService.speak(response);
            }
          } else {
            _hasError = true;
            _isLoading = false;
          }
        },
      );
    } catch (e) {
      _hasError = true;
      _isLoading = false;
    }
    notifyListeners();
  }

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  void selectImage(File image) {
    _selectedImage = image;
    notifyListeners();
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    if (message.isEmpty || _isLoading) return;

    _messages.add(
      ChatMessage(text: message, isUser: true, imagePath: _selectedImage?.path),
    );

    final imageToSend = _selectedImage;
    _selectedImage = null; // Clear image after sending
    _isLoading = true;
    _hasError = false;
    messageController.clear();
    notifyListeners();

    final result = await _sendInterviewMessageUseCase.execute(
      SendInterviewMessageParams(message: message, image: imageToSend),
    );

    result.fold(
      (failure) {
        _hasError = true;
        _isLoading = false;
        notifyListeners();
      },
      (response) async {
        if (response.hasError) {
          _hasError = true;
          _isLoading = false;
          notifyListeners();
          return;
        }

        // Clean message
        String displayMessage = response.message;
        if (response.isComplete) {
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
            displayMessage = _l10n?.interviewComplete ?? "Interview Complete";
          }
        }

        _messages.add(ChatMessage(text: displayMessage, isUser: false));
        _isLoading = false;
        _isInterviewComplete = response.isComplete;

        if (_isTtsEnabled) {
          _ttsService.speak(displayMessage);
        }

        notifyListeners();

        if (response.isComplete) {
          _lastInterviewDetails = response.extractedDetails;

          // Log to long-term memory (Holistic Agent Context)
          _cacheManager.logEvent(
            type: 'onboarding',
            data: {
              'summary': response.summaryText,
              'details': response.extractedDetails,
            },
          );

          _inviteToAssessment();
        }
      },
    );
  }

  void _inviteToAssessment() {
    _messages.add(
      ChatMessage(
        text: _l10n?.aiInviteAssessmentButton ?? "Start Alignment Check",
        isUser: false,
        isAssessmentInvite: true,
      ),
    );
    notifyListeners();
  }

  Future<void> generateCurriculum() async {
    if (_lastInterviewDetails == null) return;

    _isLoading = true;

    // Add Loading Message (Shimmer)
    final loadingMessageIndex = _messages.length;
    _messages.add(
      ChatMessage(
        text:
            _l10n?.generatingWorkout ??
            "Generating your personalized curriculum...",
        isUser: false,
        isLoading: true, // Trigger Shimmer Card
      ),
    );
    notifyListeners();

    try {
      final firebaseService = FirebaseService();
      await firebaseService.initialize();
      final allWorkouts = await firebaseService.fetchWorkoutAllList();

      final result = await _generateCurriculumUseCase.execute(
        GenerateCurriculumFromInterviewParams(
          profile: _userProfile!,
          availableWorkouts: allWorkouts,
          interviewDetails: _lastInterviewDetails!,
        ),
      );

      result.fold(
        (failure) {
          // Update in-place to error
          _messages[loadingMessageIndex] = ChatMessage(
            text: _l10n?.generationFailed ?? "Failed to generate curriculum.",
            isUser: false,
          );
          _hasError = true;
          _isLoading = false;
        },
        (curriculum) async {
          if (curriculum != null) {
            await _saveCurriculumUseCase.execute(curriculum);

            // Replace Shimmer with Result Card
            _messages[loadingMessageIndex] = ChatMessage(
              text:
                  'Curriculum created: ${curriculum.title}\nDuration: ${curriculum.estimatedMinutes} min',
              isUser: false,
              curriculum: curriculum,
            );

            _isInterviewComplete = true;
            _isLoading = false;
          } else {
            _messages[loadingMessageIndex] = ChatMessage(
              text: _l10n?.generationFailed ?? "Failed to generate curriculum.",
              isUser: false,
            );
            _hasError = true;
            _isLoading = false;
          }
        },
      );
    } catch (e) {
      _messages[loadingMessageIndex] = ChatMessage(
        text: "An error occurred.",
        isUser: false,
      );
      _hasError = true;
      _isLoading = false;
    }
    notifyListeners();
  }

  void retryConnection() {
    _hasError = false;
    notifyListeners();
    if (_messages.isEmpty) {
      _startInterview();
    } else if (_messages.isNotEmpty && _messages.last.isUser) {
      // Retry last user message
      final lastText = _messages.last.text;
      _messages.removeLast(); // Remove to re-add
      sendMessage(lastText);
    }
  }

  // Permission & Mic Logic
  Future<void> startListening({
    required VoidCallback onPermissionDenied,
  }) async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        onPermissionDenied();
        return;
      }
      final newStatus = await Permission.microphone.request();
      if (!newStatus.isGranted) return;
    }

    final available = await _sttService.initialize();
    if (available) {
      await _ttsService.stop(); // Stop TTS if speaking
      _isListening = true;
      notifyListeners();
      // Language code usually comes from context, but Controller shouldn't depend on Context.
      // We'll pass locale or default to English.
      // Ideally initialized with locale.
      _sttService.startListening(
        onResult: (text) {
          messageController.text = text;
          notifyListeners();
        },
        languageCode: _l10n?.localeName == 'ko' ? 'ko-KR' : 'en-US',
      );
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    notifyListeners();
    await _sttService.stopListening();
  }

  @override
  void dispose() {
    messageController.dispose();
    _ttsService.stop();
    // _sttService.stop(); // Service usually handles this
    super.dispose();
  }
}
