import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../../models/workout_curriculum_model.dart';
import '../../models/workout_task_model.dart';
import '../../models/user_profile_model.dart';
import '../../../core/wrappers/gemini_wrapper.dart';

/// Remote data source for Gemini AI operations
abstract class GeminiDataSource {
  Future<WorkoutCurriculumModel> generateCurriculum({
    required UserProfileModel profile,
    required String category,
    required List<WorkoutTaskModel> availableTasks,
  });
}

class GeminiDataSourceImpl implements GeminiDataSource {
  final GeminiWrapper? _injectedWrapper;

  GeminiDataSourceImpl({GeminiWrapper? wrapper}) : _injectedWrapper = wrapper;

  @override
  Future<WorkoutCurriculumModel> generateCurriculum({
    required UserProfileModel profile,
    required String category,
    required List<WorkoutTaskModel> availableTasks,
  }) async {
    try {
      // 1. Initialize Wrapper
      GeminiWrapper wrapper;
      if (_injectedWrapper != null) {
        wrapper = _injectedWrapper;
      } else {
        final apiKey = dotenv.env['GEMINI_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('GEMINI_API_KEY is missing in .env');
        }

        // Load system instruction
        final systemInstructionContent = await rootBundle.loadString(
          'assets/prompts/curriculum_planner_system_instruction.md',
        );

        final model = GenerativeModel(
          model: 'gemini-3-flash-preview',
          apiKey: apiKey,
          systemInstruction: Content.system(systemInstructionContent),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.7,
          ),
        );
        wrapper = GeminiWrapperImpl(model);
      }

      // 2. Prepare Prompt
      final taskListString = availableTasks
          .map((t) => '- [${t.id}] ${t.title} (${t.category})')
          .join('\n');

      final prompt =
          '''
User Profile:
- Name: ${profile.nickname}
- Level: ${profile.fitnessLevel}
- Goal: $category
- Health Conditions: ${profile.healthConditions}

Available Exercises (Use ONLY these IDs):
$taskListString

Generate a localized workout curriculum for this user.
''';

      // 3. Generate Content
      final content = [Content.text(prompt)];
      final response = await wrapper.generateContent(content);

      if (response.text == null) {
        throw Exception('Empty response from Gemini');
      }

      // 4. Parse JSON
      final jsonResponse = jsonDecode(response.text!) as Map<String, dynamic>;

      // Map tasks back to full objects (AI returns IDs and params)
      final generatedTasks = (jsonResponse['workoutTaskList'] as List).map((
        taskJson,
      ) {
        final taskId = taskJson['id'];
        final originalTask = availableTasks.firstWhere(
          (t) => t.id == taskId,
          orElse: () => availableTasks.first, // Fallback
        );

        return originalTask.copyWith(
          title: taskJson['title'] ?? originalTask.title,
          description: taskJson['description'] ?? originalTask.description,
          reps: taskJson['reps'] as int?,
          sets: taskJson['sets'] as int?,
          timeoutSec: taskJson['timeoutSec'] as int?,
          // Keep original images/urls as AI doesn't have them
        );
      }).toList();

      return WorkoutCurriculumModel(
        id: jsonResponse['id'] ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
        title: jsonResponse['title'] ?? 'AI Workout',
        description: jsonResponse['description'] ?? 'Personalized plan',
        thumbnail: '', // Will be handled by UI or existing logic
        workoutTasks: generatedTasks,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error generating curriculum with Gemini: $e');
      // Fallback or rethrow? For now rethrow to let UI handle it
      rethrow;
    }
  }
}
