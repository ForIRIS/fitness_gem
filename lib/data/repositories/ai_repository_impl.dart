import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/workout_task.dart';
import '../../domain/entities/workout_curriculum.dart';
import '../../domain/entities/interview_response.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/gemini_remote_datasource.dart';
import '../../services/functions_service.dart';

class AIRepositoryImpl implements AIRepository {
  final GeminiRemoteDataSource remoteDataSource;
  final FunctionsService functionsService;

  static const String _apiKeyPrefKey = 'gemini_api_key';

  String _apiKey = '';
  ChatSession? _interviewSession;

  // System Instructions cache
  String _analystSystemInstruction = '';
  String _consultantSystemInstruction = '';
  String _interviewSystemInstruction = '';
  String _curriculumSystemInstruction = '';
  String _baselineSystemInstruction = '';
  bool _instructionsLoaded = false;

  AIRepositoryImpl({
    required this.remoteDataSource,
    FunctionsService? functionsService,
  }) : functionsService = functionsService ?? FunctionsService();

  Future<void> initialize() async {
    // Load API Key
    await _initializeApiKey();
    // Load System Instructions
    await _loadSystemInstructions();
  }

  Future<void> _initializeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_apiKeyPrefKey);
    _apiKey = savedKey ?? dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  Future<void> _loadSystemInstructions() async {
    if (_instructionsLoaded) return;
    try {
      _analystSystemInstruction = await rootBundle.loadString(
        'assets/prompts/analyst_system_instruction.md',
      );
      _consultantSystemInstruction = await rootBundle.loadString(
        'assets/prompts/consultant_system_instruction.md',
      );
      _interviewSystemInstruction = await rootBundle.loadString(
        'assets/prompts/interview_system_instruction.md',
      );
      _curriculumSystemInstruction = await rootBundle.loadString(
        'assets/prompts/curriculum_planner_system_instruction.md',
      );
      _baselineSystemInstruction = await rootBundle.loadString(
        'assets/prompts/baseline_analyst_system_instruction.md',
      );
      _instructionsLoaded = true;
    } catch (e) {
      debugPrint('Error loading system instructions: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (_apiKey.isEmpty) await _initializeApiKey();
    if (!_instructionsLoaded) await _loadSystemInstructions();
  }

  @override
  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (apiKey.isEmpty) {
      await prefs.remove(_apiKeyPrefKey);
      _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    } else {
      await prefs.setString(_apiKeyPrefKey, apiKey);
      _apiKey = apiKey;
    }
  }

  @override
  Future<String> getApiKey() async {
    if (_apiKey.isEmpty) await _initializeApiKey();
    return _apiKey;
  }

  // ============ Curriculum ============

  @override
  Future<Either<Failure, WorkoutCurriculum?>> generateCurriculum({
    required UserProfile profile,
    required String category,
    required List<WorkoutTask> availableWorkouts,
  }) async {
    await _ensureInitialized();
    try {
      final workoutListText = _buildWorkoutListText(availableWorkouts);

      final prompt =
          '''
User Profile:
- Age: ${profile.age}
- Injury History: ${profile.injuryHistory}
- Goal: ${profile.goal}
- Experience Level: ${profile.experienceLevel}

Requested Category: $category

Available Workouts:
$workoutListText

Create an appropriate workout curriculum for this user. Select 2-3 exercises from the available list.
Output JSON only.
''';

      final jsonText = await remoteDataSource.generateContent(
        apiKey: _apiKey,
        systemInstruction: _curriculumSystemInstruction,
        prompt: prompt,
        responseMimeType: 'application/json',
      );

      if (jsonText == null) {
        return const Right(null);
      }

      final curriculum = await _parseCurriculumJson(
        jsonText,
        availableWorkouts,
      );
      return Right(curriculum);
    } catch (e) {
      return Left(ServerFailure('Generate Curriculum Failed: $e'));
    }
  }

  @override
  Future<Either<Failure, WorkoutCurriculum?>> chatForCurriculum({
    required String userMessage,
    required UserProfile profile,
    required List<WorkoutTask> availableWorkouts,
  }) async {
    await _ensureInitialized();
    try {
      final workoutListText = _buildWorkoutListText(availableWorkouts);

      final prompt =
          '''
User is chatting with the AI to request a workout curriculum change.

User Profile:
- Age: ${profile.age}
- Injury History: ${profile.injuryHistory}
- Goal: ${profile.goal}
- Experience Level: ${profile.experienceLevel}

User Request: "$userMessage"

Available Workouts:
$workoutListText

Based on the user's request, create an appropriate workout curriculum.
If the user asks for a specific body part (lower body, upper body, core, etc.), select exercises from that category.
Output JSON only.
''';

      final jsonText = await remoteDataSource.generateContent(
        apiKey: _apiKey,
        systemInstruction: _curriculumSystemInstruction,
        prompt: prompt,
        responseMimeType: 'application/json',
      );

      if (jsonText == null) {
        return const Right(null);
      }

      final curriculum = await _parseCurriculumJson(
        jsonText,
        availableWorkouts,
      );
      return Right(curriculum);
    } catch (e) {
      return Left(ServerFailure('Chat Curriculum Failed: $e'));
    }
  }

  @override
  Future<Either<Failure, WorkoutCurriculum?>>
  generateCurriculumFromInterviewResult({
    required UserProfile profile,
    required List<WorkoutTask> availableWorkouts,
    required Map<String, String> interviewDetails,
  }) async {
    await _ensureInitialized();
    try {
      final workoutListText = _buildWorkoutListText(availableWorkouts);

      final prompt =
          '''
User Profile:
- Age: ${profile.age}
- Injury History: ${profile.injuryHistory}
- Goal: ${profile.goal}
- Experience Level: ${profile.experienceLevel}

Interview Details (Extracted Context):
${json.encode(interviewDetails)}

Available Workouts:
$workoutListText

Create a highly personalized workout curriculum based on the DEEP INTERVIEW results.
Select appropriate exercises that match the user's specific needs found in the interview.
Output JSON only.
''';

      final jsonText = await remoteDataSource.generateContent(
        apiKey: _apiKey,
        systemInstruction: _curriculumSystemInstruction,
        prompt: prompt,
        responseMimeType: 'application/json',
      );

      if (jsonText == null) {
        return const Right(null);
      }

      final curriculum = await _parseCurriculumJson(
        jsonText,
        availableWorkouts,
      );
      return Right(curriculum);
    } catch (e) {
      return Left(ServerFailure('Generate from Interview Failed: $e'));
    }
  }

  // ============ Video Analysis ============

  @override
  Future<Either<Failure, Map<String, dynamic>?>> analyzeVideoSession({
    required File rgbVideoFile,
    required File controlNetVideoFile,
    required UserProfile profile,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    bool isLastSet = false,
    String language = 'Korean',
  }) async {
    await _ensureInitialized();
    try {
      // 1. Upload Videos
      final rgbUri = await remoteDataSource.uploadFile(
        apiKey: _apiKey,
        file: rgbVideoFile,
      );
      if (rgbUri == null) {
        return const Left(ServerFailure('Failed to upload RGB video'));
      }

      final controlNetUri = await remoteDataSource.uploadFile(
        apiKey: _apiKey,
        file: controlNetVideoFile,
      );
      if (controlNetUri == null) {
        return const Left(ServerFailure('Failed to upload ControlNet video'));
      }

      // Wait for processing
      await Future.delayed(const Duration(seconds: 3));

      // 2. Analyst Step (Direct Client Call - Fast & Efficient for Hackathon)
      final inputContext = {
        "query_type": "INTER_SET_ANALYSIS",
        "user_profile": profile.toJson(),
        "current_session_context": {
          "exercise_name": exerciseName,
          "set_number": setNumber,
          "total_planned_sets": totalSets,
        },
        "request_task": isLastSet ? "FINAL_ASSESSMENT" : "INTER_SET_CHECK",
        "user_language": language,
      };

      final analystJson = await remoteDataSource.analyzeInterSet(
        apiKey: _apiKey,
        systemInstruction: _analystSystemInstruction,
        inputContext: inputContext,
        rgbUri: rgbUri,
        controlNetUri: controlNetUri,
      );

      if (analystJson == null) {
        return const Left(ServerFailure('Analyst returned null'));
      }

      // 3. Consultant Step
      final consultantPrompt =
          '''
User Profile: ${json.encode(profile.toJson())}
Current Plan: ${json.encode({"set": setNumber})}
Analyst Report: ${json.encode(analystJson)}
User Language: $language

Please provide the Next Step advice in the User Language.
''';

      final consultantResponse = await remoteDataSource.generateContent(
        apiKey: _apiKey,
        systemInstruction: _consultantSystemInstruction,
        prompt: consultantPrompt,
        responseMimeType: 'application/json',
      );

      // 4. Parse Consultant Response
      Map<String, dynamic> adviceJson = {};
      if (consultantResponse != null) {
        try {
          adviceJson = json.decode(consultantResponse);
        } catch (e) {
          debugPrint('Error parsing consultant response: $e');
        }
      }

      // 5. Map to UI format
      final result = {
        'session_summary': {
          'exercise_name': exerciseName,
          'total_score':
              analystJson['performance_analysis']?['stability_score'] ?? 0,
          'safety_flag': analystJson['safety_status']?['risk_flag'] ?? false,
        },
        'feedback': {
          'main_issue':
              analystJson['safety_status']?['primary_risk_area'] ?? 'None',
          'tts_message':
              adviceJson['tts_message'] ??
              (language == 'English' ? "Great job!" : "Well done."),
          'detailed_analysis': analystJson,
          'next_step_adjustments': adviceJson['next_set_adjustments'],
        },
      };

      // Cost Logging (AI Wrapper Best Practice)
      const double inputRate = 0.075 / 1000000; // \$0.075 per 1M tokens (Flash)
      const double outputRate = 0.3 / 1000000; // \$0.3 per 1M tokens (Flash)
      debugPrint('[AI_METERING] Multimodal analysis session complete.');
      debugPrint('[AI_METERING] Model: Gemini 3 Flash');
      debugPrint(
        '[AI_METERING] Rates: Input=\$$inputRate, Output=\$$outputRate',
      );
      debugPrint(
        '[AI_METERING] Highlight Duration: 10s (Target FPS: 15, Resolution: 640x480)',
      );

      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Video Analysis Failed: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> analyzeFallDetection({
    required File videoFile,
    required UserProfile profile,
  }) async {
    await _ensureInitialized();
    try {
      final videoUri = await remoteDataSource.uploadFile(
        apiKey: _apiKey,
        file: videoFile,
      );
      if (videoUri == null) {
        return const Left(ServerFailure('Failed to upload video'));
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      final inputContext = {
        "query_type": "FALL_VERIFICATION",
        "user_profile": profile.toJson(),
      };

      final analystJson = await remoteDataSource.analyzeInterSet(
        apiKey: _apiKey,
        systemInstruction: _analystSystemInstruction,
        inputContext: inputContext,
        rgbUri: videoUri,
        controlNetUri: videoUri,
      );

      if (analystJson == null) return const Right(false);

      if (analystJson['fall_detected'] == true ||
          analystJson['safety_status']?['risk_flag'] == true) {
        return const Right(true);
      }

      return const Right(false);
    } catch (e) {
      return Left(ServerFailure('Fall Detection Analysis Failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> analyzeBaselineVideo(
    String videoPath,
  ) async {
    await _ensureInitialized();
    try {
      final videoFile = File(videoPath);
      final videoUri = await remoteDataSource.uploadFile(
        apiKey: _apiKey,
        file: videoFile,
      );

      if (videoUri == null) {
        return const Left(ServerFailure('Failed to upload baseline video'));
      }

      // Wait for processing
      await Future.delayed(const Duration(seconds: 2));

      final prompt = '''
TASK: BASELINE_ASSESSMENT
ANALYZE: The user is performing an Air Squat for a baseline fitness assessment.

metrics_to_extract:
- stability_score (0-100): How stable is the core and balance?
- mobility_score (0-100): Depth of squat and ankle/hip mobility.
- alignment_issues (List<String>): e.g., "Knees caving in", "Heels lifting", "Excessive forward lean".
- recommendation (String): Specific advice based on the form.

Output JSON only.
''';

      final responseMap = await remoteDataSource.analyzeBaseline(
        apiKey: _apiKey,
        systemInstruction: _baselineSystemInstruction,
        prompt: prompt,
        videoUri: videoUri,
      );

      if (responseMap == null) {
        return const Left(ServerFailure('Baseline analysis returned null'));
      }

      return Right(responseMap);
    } catch (e) {
      return Left(ServerFailure('Baseline Analysis Failed: $e'));
    }
  }

  // ============ Interview ============

  @override
  Future<Either<Failure, String?>> startInterviewChat(
    UserProfile profile,
  ) async {
    await _ensureInitialized();
    try {
      _interviewSession = remoteDataSource.startChat(
        apiKey: _apiKey,
        systemInstruction: _interviewSystemInstruction,
      );

      final initialPrompt =
          '''
TASK: START_INTERVIEW

User Profile:
- Age: ${profile.age}
- Injury History: ${profile.injuryHistory.isEmpty ? "None" : profile.injuryHistory}
- Goal: ${profile.goal.isEmpty ? "Undecided" : profile.goal}
- Experience Level: ${profile.experienceLevel}
- Target Exercise: ${profile.targetExercise}

Please start the interview in English.
''';

      final responseText = await remoteDataSource.sendMessage(
        chatSession: _interviewSession!,
        message: initialPrompt,
      );

      return Right(responseText);
    } catch (e) {
      return Left(ServerFailure('Start Interview Failed: $e'));
    }
  }

  @override
  Future<Either<Failure, InterviewResponse>> sendInterviewMessage(
    String userMessage,
  ) async {
    if (_interviewSession == null) {
      return Left(const ServerFailure('No active interview session'));
    }

    try {
      final responseText = await remoteDataSource.sendMessage(
        chatSession: _interviewSession!,
        message: userMessage,
      );

      final text = responseText ?? '';

      // Check for completion JSON
      if (text.contains('"interview_complete": true') ||
          text.contains('"interview_complete":true')) {
        final jsonMatch = RegExp(
          r'\{[\s\S]*"interview_complete"[\s\S]*\}',
        ).firstMatch(text);

        if (jsonMatch != null) {
          try {
            final jsonData = json.decode(jsonMatch.group(0)!);
            return Right(
              InterviewResponse(
                message: text,
                isComplete: true,
                summaryText: jsonData['summary_text'],
                extractedDetails: jsonData['extracted_details'] != null
                    ? Map<String, String>.from(
                        (jsonData['extracted_details'] as Map).map(
                          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
                        ),
                      )
                    : null,
              ),
            );
          } catch (e) {
            debugPrint('JSON parse error: $e');
          }
        }
      }

      return Right(InterviewResponse(message: text, isComplete: false));
    } catch (e) {
      if (e.toString().contains('Unhandled format for Content')) {
        return Right(
          InterviewResponse(
            message: 'Invalid message format. Please restart the interview.',
            isComplete: false,
            hasError: true,
          ),
        );
      }
      return Left(ServerFailure('Interview Error: $e'));
    }
  }

  // ============ Helpers ============

  String _buildWorkoutListText(List<WorkoutTask> workouts) {
    final buffer = StringBuffer();
    for (final task in workouts) {
      buffer.writeln('- ID: ${task.id}');
      buffer.writeln('  Title: ${task.title}');
      buffer.writeln('  Description: ${task.description}');
      buffer.writeln('  Category: ${task.category}');
      buffer.writeln('  Difficulty: ${task.difficulty}');
      buffer.writeln('  Default Reps: ${task.reps}, Sets: ${task.sets}');
      buffer.writeln();
    }
    return buffer.toString();
  }

  Future<WorkoutCurriculum> _parseCurriculumJson(
    String jsonText,
    List<WorkoutTask> availableWorkouts,
  ) async {
    Map<String, dynamic> jsonData;
    try {
      jsonData = json.decode(jsonText) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding curriculum JSON: $e');
      // If decoding fails, try to extract JSON from markdown if present
      final jsonMatch = RegExp(
        r'```json\s*([\s\S]*?)\s*```',
      ).firstMatch(jsonText);
      if (jsonMatch != null) {
        jsonData = json.decode(jsonMatch.group(1)!) as Map<String, dynamic>;
      } else {
        rethrow;
      }
    }

    final workoutList = jsonData['workoutTaskList'] as List<dynamic>? ?? [];
    final selectedTasks = <WorkoutTask>[];

    for (final item in workoutList) {
      if (item is Map<String, dynamic>) {
        final id = item['id']?.toString() ?? '';
        final task = availableWorkouts
            .firstWhere(
              (t) => t.id == id,
              orElse: () => availableWorkouts.first,
            )
            .copyWith(); // Create copy to modify

        // Extract adjustments from the item itself
        int? reps;
        int? sets;
        int? durationSec;

        if (item['reps'] != null) {
          reps = int.tryParse(item['reps'].toString());
        }
        if (item['sets'] != null) {
          sets = int.tryParse(item['sets'].toString());
        }
        if (item['durationSec'] != null) {
          durationSec = int.tryParse(item['durationSec'].toString());
        }

        // Also check "adjustments" map for backward compatibility, though deprecated in prompt
        // (Leaving it out for now to strictly follow new logic)

        selectedTasks.add(
          task.withAdjustment(reps: reps, sets: sets, durationSec: durationSec),
        );
      } else if (item is String) {
        // Fallback for list of IDs
        final id = item;
        final task = availableWorkouts.firstWhere(
          (t) => t.id == id,
          orElse: () => availableWorkouts.first,
        );
        selectedTasks.add(task);
      }
    }

    // Enrich Media Info
    await _enrichTaskMediaInfo(selectedTasks);

    return WorkoutCurriculum(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title:
          jsonData['title'] ??
          jsonData['curriculum_title'] ??
          'Generated Workout',
      description:
          jsonData['description'] ?? jsonData['curriculum_description'] ?? '',
      thumbnail: '',
      workoutTasks: selectedTasks,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _enrichTaskMediaInfo(List<WorkoutTask> tasks) async {
    final missingInfoTaskIds = tasks
        .where((t) => !t.hasMediaInfo)
        .map((t) => t.id)
        .toSet() // Use Set to avoid duplicates
        .toList();

    if (missingInfoTaskIds.isNotEmpty) {
      final extraInfos = await functionsService.getWorkoutAssets(
        missingInfoTaskIds,
      );
      for (var i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        final info = extraInfos.firstWhere(
          (info) => info['id'] == task.id,
          orElse: () => <String, dynamic>{},
        );

        if (info.isNotEmpty) {
          tasks[i] = task.withMediaInfo(
            thumbnail: info['thumbnailUrl'] as String?,
            readyPoseImageUrl: info['samplePoseUrl'] as String?,
            exampleVideoUrl: info['videoUrl'] as String?,
            // bundleUrl could also be stored if needed
          );
        }
      }
    }
  }
}
