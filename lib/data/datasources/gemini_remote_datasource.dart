import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

abstract class GeminiRemoteDataSource {
  /// Generate content using the Gemini SDK
  Future<String?> generateContent({
    required String apiKey,
    required String systemInstruction,
    required String prompt,
    String model = 'gemini-3-flash-preview',
    String? responseMimeType,
  });

  /// Upload a file for multimodal use
  Future<String?> uploadFile({required String apiKey, required File file});

  /// specific raw HTTP call for inter-set analysis (Multimodal + System Instruction)
  Future<Map<String, dynamic>?> analyzeInterSet({
    required String apiKey,
    required String systemInstruction,
    required Map<String, dynamic> inputContext,
    required String rgbUri,
    required String controlNetUri,
    String mimeType = 'video/mp4',
    String model = 'gemini-3-flash-preview',
  });

  /// Analyze baseline video (Single Video) via raw HTTP
  Future<Map<String, dynamic>?> analyzeBaseline({
    required String apiKey,
    required String systemInstruction,
    required String prompt,
    required String videoUri,
    String model = 'gemini-3-flash-preview',
  });

  /// Start a chat session
  ChatSession startChat({
    required String apiKey,
    required String systemInstruction,
    String model = 'gemini-3-flash-preview',
  });

  /// Send message to existing session
  Future<String?> sendMessage({
    required ChatSession chatSession,
    required String message,
  });

  /// Generate post-workout summary using the Storyteller agent
  Future<Map<String, dynamic>?> generatePostWorkoutSummary({
    required String apiKey,
    required String systemInstruction,
    required String userLanguage,
    required String exerciseName,
    required int initialStability,
    required int initialMobility,
    required int sessionStability,
    required int totalReps,
    String? primaryFaultDetected,
  });
}
