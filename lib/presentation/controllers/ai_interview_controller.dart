import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // For TextEditingController
import 'package:permission_handler/permission_handler.dart';

import '../../core/di/injection.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/interview_response.dart';
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

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isCard = false,
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

  Future<void> initialize(UserProfile profile) async {
    _userProfile = profile;
    await _ttsService.initialize();
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
            // response is String? from usecase
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
            displayMessage =
                "Interview Complete"; // Fallback, usually localized in View
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
          await _processInterviewResult(
            response.summaryText,
            response.extractedDetails,
          );
        }
      },
    );
  }

  Future<void> _processInterviewResult(
    String? summaryText,
    Map<String, String>? extractedDetails,
  ) async {
    if (extractedDetails == null) return;

    _isLoading = true;
    _messages.add(
      ChatMessage(
        text: "Generating your personalized curriculum...",
        isUser: false,
      ),
    );
    notifyListeners();

    try {
      final firebaseService =
          FirebaseService(); // Ideally injected, but kept as per original logic for now
      await firebaseService.initialize(); // Lightweight
      final allWorkouts = await firebaseService.fetchWorkoutAllList();

      final result = await _generateCurriculumUseCase.execute(
        GenerateCurriculumFromInterviewParams(
          profile: _userProfile!,
          availableWorkouts: allWorkouts,
          interviewDetails: extractedDetails,
        ),
      );

      result.fold(
        (failure) {
          _messages.add(
            ChatMessage(text: "Failed to generate curriculum.", isUser: false),
          );
          _hasError = true;
          _isLoading = false;
        },
        (curriculum) async {
          if (curriculum != null) {
            await _saveCurriculumUseCase.execute(curriculum);

            _messages.add(
              ChatMessage(
                text:
                    'Curriculum created: ${curriculum.title}\nDuration: ${curriculum.estimatedMinutes} min',
                isUser: false,
              ),
            );

            // We need to signal the View to show the "Assessment Card"
            // Since card creation involves UI widgets (Navigator, context),
            // we might instead push a special "System Message" that the View renders as a card.
            _messages.add(
              ChatMessage(
                text: '',
                isUser: false,
                isCard: true,
                // Widget will be built in View based on isCard flag
              ),
            );

            _isInterviewComplete = true;
            _isLoading = false;
          } else {
            _messages.add(
              ChatMessage(
                text: "Failed to generate curriculum.",
                isUser: false,
              ),
            );
            _hasError = true;
            _isLoading = false;
          }
        },
      );
    } catch (e) {
      _messages.add(ChatMessage(text: "An error occurred.", isUser: false));
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
        languageCode: 'en-US', // TODO: Make dynamic
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
