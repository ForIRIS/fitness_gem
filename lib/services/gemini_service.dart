import 'dart:io';
import 'package:flutter/foundation.dart';

import '../domain/entities/user_profile.dart';
import '../domain/entities/workout_task.dart';
import '../domain/entities/workout_curriculum.dart';
import '../domain/entities/interview_response.dart';
import '../domain/repositories/ai_repository.dart';
import '../data/repositories/ai_repository_impl.dart';
import '../data/datasources/gemini_remote_datasource_impl.dart';

export '../domain/entities/interview_response.dart';

/// GeminiService - Gemini AI Integration Service
@Deprecated(
  'Use AIRepository directly or via UseCases. This service is being removed.',
)
class GeminiService {
  final AIRepository _aiRepository;

  GeminiService({AIRepository? aiRepository})
    : _aiRepository =
          aiRepository ??
          AIRepositoryImpl(remoteDataSource: GeminiRemoteDataSourceImpl());

  Future<void> initialize() async {
    // No-op for now, repository handles initialization lazily or explicitly
  }

  Future<void> setApiKey(String newKey) async {
    await _aiRepository.setApiKey(newKey);
  }

  Future<String> getUserApiKey() async {
    return _aiRepository.getApiKey();
  }

  // Hardcoded prompts removed - now loaded from assets

  // ============ Curriculum Generation ============

  /// Generate Curriculum
  Future<WorkoutCurriculum?> generateCurriculum({
    required UserProfile profile,
    required String category,
    required List<WorkoutTask> availableWorkouts,
  }) async {
    final result = await _aiRepository.generateCurriculum(
      profile: profile,
      category: category,
      availableWorkouts: availableWorkouts,
    );
    return result.fold((l) {
      debugPrint('generateCurriculum error: $l');
      return null;
    }, (r) => r);
  }

  // ============ Video Analysis (HTTP File Upload) ============

  Future<Map<String, dynamic>?> analyzeVideoSession({
    required File rgbVideoFile,
    required File controlNetVideoFile,
    required UserProfile profile,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    bool isLastSet = false,
    String language = 'Korean',
  }) async {
    final result = await _aiRepository.analyzeVideoSession(
      rgbVideoFile: rgbVideoFile,
      controlNetVideoFile: controlNetVideoFile,
      profile: profile,
      exerciseName: exerciseName,
      setNumber: setNumber,
      totalSets: totalSets,
      isLastSet: isLastSet,
      language: language,
    );
    return result.fold((l) {
      debugPrint('analyzeVideoSession error: $l');
      return null;
    }, (r) => r);
  }

  // ============ AI Consultation (Chat) ============

  /// Request Curriculum Change via AI Chat
  Future<WorkoutCurriculum?> chatForCurriculum({
    required String userMessage,
    required UserProfile profile,
    required List<WorkoutTask> availableWorkouts,
  }) async {
    final result = await _aiRepository.chatForCurriculum(
      userMessage: userMessage,
      profile: profile,
      availableWorkouts: availableWorkouts,
    );
    return result.fold((l) {
      debugPrint('chatForCurriculum error: $l');
      return null;
    }, (r) => r);
  }

  Future<WorkoutCurriculum?> generateCurriculumFromInterviewResult({
    required UserProfile profile,
    required List<WorkoutTask> availableWorkouts,
    required Map<String, String> interviewDetails,
  }) async {
    final result = await _aiRepository.generateCurriculumFromInterviewResult(
      profile: profile,
      availableWorkouts: availableWorkouts,
      interviewDetails: interviewDetails,
    );
    return result.fold((l) {
      debugPrint('generateCurriculumFromInterviewResult error: $l');
      return null;
    }, (r) => r);
  }

  // ============ AI Interview ============

  Future<String?> startInterviewChat(UserProfile profile) async {
    final result = await _aiRepository.startInterviewChat(profile);
    return result.fold((l) => null, (r) => r);
  }

  Future<InterviewResponse> sendInterviewMessage(String userMessage) async {
    final result = await _aiRepository.sendInterviewMessage(userMessage);
    return result.fold(
      (l) => InterviewResponse(
        message: 'Error: ${l.toString()}',
        isComplete: false,
        hasError: true,
      ),
      (r) => r,
    );
  }

  // Deprecated image chat
  Future<InterviewResponse> chatWithImage({
    required String userMessage,
    required File imageFile,
    UserProfile? profile, // Added for compatibility
  }) async {
    return InterviewResponse(
      message: 'Feature migrating...',
      isComplete: false,
    );
  }

  /// End Interview Session
  void endInterviewSession() {
    // No-op for now unless we add this to Interface
  }

  // ============ Fall Detection Analysis ============

  /// Analyze Fall Detection
  Future<bool> analyzeFallDetection({
    required File videoFile,
    required UserProfile profile,
  }) async {
    try {
      // This method's implementation was removed from GeminiService
      // and should be handled by the repository or a dedicated service.
      // Returning false as a placeholder.
      debugPrint(
        'analyzeFallDetection is deprecated in GeminiService. Use repository.',
      );
      return false;
    } catch (e) {
      debugPrint('Fall detection error: $e');
      return false;
    }
  }

  // ============ 최종 리포트 생성 ============

  /// 세션 완료 후 최종 리포트 생성
  Future<String?> generateFinalReport({
    required UserProfile profile,
    required List<Map<String, dynamic>> setAnalyses,
  }) async {
    debugPrint('generateFinalReport: Migrating to Repository...');
    return "Session Complete. (Report generation migrating)";
  }
}

/// 인터뷰 응답 모델
