import 'package:flutter/widgets.dart'; // For TextEditingController
import 'package:permission_handler/permission_handler.dart';

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

// We will define ChatMessage here or in a separate file.
// For now, let's redefine it here or make it generic.
// Actually, let's assume we'll move ChatMessage to a shared model file, but for now I'll include a simple class or use the one from View via callbacks?
// No, Controller should hold the state.

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isCard;
  final Widget? cardWidget;
  final bool isLoading;
  final bool isAssessmentInvite;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isCard = false,
    this.isLoading = false,
    this.isAssessmentInvite = false,
    this.cardWidget,
  });
}

class AIInterviewController extends ChangeNotifier {
  final StartInterviewUseCase _startInterviewUseCase;
  final SendInterviewMessageUseCase _sendInterviewMessageUseCase;
  final GenerateCurriculumFromInterviewUseCase _generateCurriculumUseCase;
  final SaveCurriculumUseCase _saveCurriculumUseCase;
  final TTSService _ttsService;
  final STTService _sttService;

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
       _sttService = sttService ?? getIt<STTService>();

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

  Future<void> sendMessage(String message) async {
    if (message.isEmpty || _isLoading) return;

    _messages.add(ChatMessage(text: message, isUser: true));
    _isLoading = true;
    _hasError = false;
    messageController.clear();
    notifyListeners();

    final result = await _sendInterviewMessageUseCase.execute(message);

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
              text: 'Curriculum Created', // Placeholder text, View renders card
              isUser: false,
              isCard: true,
              // Ideally pass curriculum data here if View needs it,
              // but current architecture might rely on Repository/State elsewhere.
              // For now, let's assume View fetches latest or we re-trigger.
              // Actually, looking at original code, it just added a card message.
            );

            // Add a text summary before or part of the card?
            // Original code added two messages: text summary AND card.
            // Requirement: "Refactor Shimmer Component: Ensure the Shimmer loader and the final Curriculum Card share the same state/ID."
            // So we should replace the Shimmer with the Card.

            _messages.add(
              ChatMessage(
                text:
                    'Curriculum created: ${curriculum.title}\nDuration: ${curriculum.estimatedMinutes} min',
                isUser: false,
              ),
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
