import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';
import '../models/workout_task.dart';
import '../models/workout_curriculum.dart';

/// GeminiService - Gemini AI Integration Service
class GeminiService {
  static const String _apiKeyPrefKey = 'gemini_api_key';

  static const String _uploadUrl =
      'https://generativelanguage.googleapis.com/upload/v1beta/files';
  static const String _generateUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  String _apiKey = '';
  GenerativeModel? _model;

  // ... (system instructions omitted for brevity in diff, but they are separate blocks in the file)

  GeminiService() {
    // 1. Initialize with dotenv immediately (Synchronous) to prevent race conditions
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _initModel();

    // 2. Load user override asynchronously
    _initializeApiKey();

    // 3. Load prompts
    _loadSystemInstructions();
  }

  /// Initialize API Key (Check SharedPreferences)
  Future<void> _initializeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_apiKeyPrefKey);

    // Overwrite only if saved key exists
    if (savedKey != null && savedKey.isNotEmpty) {
      _apiKey = savedKey;
      _initModel();
    }
  }

  /// Initialize Model
  void _initModel() {
    if (_apiKey.isEmpty) return;

    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
      systemInstruction: Content.system(_analystSystemInstruction),
    );
  }

  /// Change API Key
  Future<void> setApiKey(String newKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (newKey.isEmpty) {
      await prefs.remove(_apiKeyPrefKey);
      _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    } else {
      await prefs.setString(_apiKeyPrefKey, newKey);
      _apiKey = newKey;
    }
    _initModel();
  }

  /// Get current valid API Key (Internal use)
  Future<String> getApiKey() async {
    if (_apiKey.isNotEmpty) return _apiKey;

    // Re-check
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPrefKey) ??
        dotenv.env['GEMINI_API_KEY'] ??
        '';
  }

  /// Get user configured API Key for UI display (Settings screen)
  Future<String> getUserApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPrefKey) ?? '';
  }

  // System Instructions - Store loaded data
  String _analystSystemInstruction = '';
  String _consultantSystemInstruction = '';

  /// Load System Instructions from assets
  Future<void> _loadSystemInstructions() async {
    try {
      _analystSystemInstruction = await rootBundle.loadString(
        'assets/prompts/analyst_system_instruction.md',
      );
      _consultantSystemInstruction = await rootBundle.loadString(
        'assets/prompts/consultant_system_instruction.md',
      );
      debugPrint('System Instructions loaded from assets.');

      // Re-initialize model (Apply new instructions)
      _initModel();
    } catch (e) {
      debugPrint('Error loading system instructions: $e');
      // Fallback values if needed, or keeping empty string
    }
  }

  // System Instructions - For Curriculum Generation
  static const String _curriculumSystemInstruction = '''
**ROLE & OBJECTIVE**
You are "CoreFit AI Curriculum Planner." Your task is to create personalized workout curricula based on user profiles and available exercises.

**INPUT**
1. User Profile (Age, Injury History, Goal, Experience Level)
2. Requested workout category (squat/push/core/lunge)
3. Available workout list from the app's exercise library

**OUTPUT FORMAT**
- **Format**: JSON only. No Markdown code blocks.
- Output a JSON array of workout IDs that form the optimal curriculum.
- Consider user's injury history to avoid unsafe exercises.
- Match difficulty level to user's experience.

**JSON SCHEMA**
{
  "curriculum_title": "String (Korean)",
  "curriculum_description": "String (Korean, brief explanation)",
  "workout_ids": ["workout_id_1", "workout_id_2", ...],
  "adjustments": {
    "workout_id": {
      "reps": Integer,
      "sets": Integer
    }
  },
  "reasoning": "String (Korean, why these exercises were chosen)"
}
''';

  // System Instructions - For AI Interview
  static const String _interviewSystemInstruction = '''
**MODE: DEEP INTERVIEWER**
You are a professional fitness consultant conducting a deep interview to understand the user better.

**Your Goal**:
Gather detailed context that wasn't captured in the basic onboarding form.
- Ask **ONE question at a time**. Do not overwhelm the user.
- Ask max **3-5 questions** total.
- Be polite, empathetic, and professional.
- Speak in **Korean**.

**Input Context**:
You will receive the user's basic info (Age, Injury, Goal, Experience Level, Target Exercise). Use this to formulate relevant questions.

**Example Questions**:
- If user has "Injury: 무릎", ask: "무릎 통증은 어떤 상황에서 발생하나요? 움직일 때인가요, 아니면 가만히 있을 때도 아프신가요?"
- If user has "Goal: 다이어트", ask: "평소 식습관은 어떠신가요? 규칙적으로 식사하시나요?"
- If user is "Beginner", ask: "운동 경험이 적으시다면, 어떤 운동이 가장 해보고 싶으신가요?"

**Interview Progress**:
Keep track of how many questions you have asked. After 3-5 meaningful exchanges, conclude the interview.

**Termination & Extraction (CRITICAL)**:
When you have gathered enough info (or after 5 turns), you MUST output the final summary.
Say "감사합니다! 프로필이 업데이트되었습니다." followed by JSON in this EXACT format:

```json
{
  "interview_complete": true,
  "summary_text": "String (Korean, summarized bio for display, 2-3 sentences)",
  "extracted_details": {
    "injury_specifics": "String (or null if no injury)",
    "lifestyle_notes": "String (daily routine, work style, etc.)",
    "diet_preference": "String (or null)",
    "stress_level": "String (or null)",
    "exercise_preference": "String (preferred workout style)",
    "available_time": "String (how much time for exercise)"
  }
}
```

**IMPORTANT**:
- Only output JSON when concluding the interview.
- During the interview, respond naturally in Korean as a friendly consultant.
- If the user wants to skip or says they don't want to answer, respect that and conclude early.
''';

  // ============ Curriculum Generation ============

  /// Generate Curriculum
  Future<WorkoutCurriculum?> generateCurriculum({
    required UserProfile profile,
    required String category,
    required List<WorkoutTask> availableWorkouts,
  }) async {
    try {
      // Create workout list text to send to Gemini
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

      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
        systemInstruction: Content.system(_curriculumSystemInstruction),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final jsonText = response.text;

      if (jsonText == null) return null;

      final jsonData = json.decode(jsonText) as Map<String, dynamic>;

      // Find WorkoutTask by selected ID
      final workoutIds =
          (jsonData['workout_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final adjustments =
          jsonData['adjustments'] as Map<String, dynamic>? ?? {};

      final selectedTasks = <WorkoutTask>[];
      for (final id in workoutIds) {
        final task = availableWorkouts.firstWhere(
          (t) => t.id == id,
          orElse: () => availableWorkouts.first,
        );

        // Apply reps/sets adjustments from Gemini
        if (adjustments.containsKey(id)) {
          final adj = adjustments[id] as Map<String, dynamic>;
          task.applyAdjustment(
            newReps: adj['reps'] as int?,
            newSets: adj['sets'] as int?,
          );
        }

        selectedTasks.add(task);
      }

      return WorkoutCurriculum(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: jsonData['curriculum_title'] ?? '오늘의 운동',
        description: jsonData['curriculum_description'] ?? '',
        thumbnail: '',
        workoutTaskList: selectedTasks,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error generating curriculum: $e');
      return null;
    }
  }

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

  // ============ Video Analysis (HTTP File Upload) ============

  /// Analyze Video (Source A: RGB, Source B: ControlNet)
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
    try {
      // 1. Upload both videos
      debugPrint('Uploading RGB video...');
      final rgbUri = await _uploadFile(rgbVideoFile);
      if (rgbUri == null) return null;

      debugPrint('Uploading ControlNet video...');
      final controlNetUri = await _uploadFile(controlNetVideoFile);
      if (controlNetUri == null) return null;

      // 2. Wait for video processing
      await Future.delayed(const Duration(seconds: 3));

      // 3. Request analysis
      debugPrint('Requesting analysis...');
      return await _generateContentWithVideos(
        rgbUri: rgbUri,
        controlNetUri: controlNetUri,
        profile: profile,
        exerciseName: exerciseName,
        setNumber: setNumber,
        totalSets: totalSets,
        isLastSet: isLastSet,
        language: language,
      );
    } catch (e) {
      debugPrint('Error in video analysis: $e');
      return null;
    }
  }

  /// Upload File
  Future<String?> _uploadFile(File file) async {
    try {
      final uri = Uri.parse('$_uploadUrl?key=$_apiKey');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      request.fields['file'] = json.encode({
        'display_name':
            'workout_video_${DateTime.now().millisecondsSinceEpoch}',
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);
        return jsonData['file']['uri'];
      } else {
        debugPrint('Upload failed: $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // ============ NEW: Inter-Set Analysis Pipeline ============

  /// 1. Analyst Step: Analyze the set context (Video + Telemetry)
  Future<Map<String, dynamic>?> analyzeInterSet({
    required Map<String, dynamic> inputContext,
    required String rgbUri,
    required String controlNetUri,
  }) async {
    try {
      final uri = Uri.parse('$_generateUrl?key=$_apiKey');

      final analystBody = json.encode({
        'systemInstruction': {
          'parts': [
            {'text': _analystSystemInstruction},
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': json.encode(inputContext)},
              {
                'file_data': {'mime_type': 'video/mp4', 'file_uri': rgbUri},
              },
              {
                'file_data': {
                  'mime_type': 'video/mp4',
                  'file_uri': controlNetUri,
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: analystBody,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) {
          return json.decode(text);
        }
      } else {
        debugPrint('Analyst failed: ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('Analyst Error: $e');
      return null;
    }
  }

  /// 2. Consultant Step: Generate advice based on Analyst data
  Future<String?> consultAfterSet({
    required UserProfile profile,
    required Map<String, dynamic> analystData,
    required Map<String, dynamic> currentPlan,
    String language = 'Korean', // Default fallback
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
        systemInstruction: Content.system(_consultantSystemInstruction),
      );

      final prompt =
          '''
User Profile: ${json.encode(profile.toJson())}
Current Plan: ${json.encode(currentPlan)}
Analyst Report: ${json.encode(analystData)}
User Language: $language

Please provide the Next Step advice in the User Language.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      debugPrint('Consultant Error: $e');
      return null;
    }
  }

  /// Legacy integration (Auto-Pipeline)
  Future<Map<String, dynamic>?> _generateContentWithVideos({
    required String rgbUri,
    required String controlNetUri,
    required UserProfile profile,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    bool isLastSet = false,
    String language = 'Korean',
  }) async {
    // Construct the context expected by the new Analyst
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

    // 1. Call Analyst
    final analystJson = await analyzeInterSet(
      inputContext: inputContext,
      rgbUri: rgbUri,
      controlNetUri: controlNetUri,
    );

    if (analystJson == null) return null;

    // 2. Call Consultant (Auto-mode for now)
    final advice = await consultAfterSet(
      profile: profile,
      analystData: analystJson,
      currentPlan: {"set": setNumber},
      language: language,
    );

    // 3. Map back to old format for UI compatibility
    return {
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
            advice ?? (language == 'English' ? "Great job!" : "수고하셨습니다."),
        'detailed_analysis': analystJson,
      },
    };
  }

  // ============ AI Consultation (Chat) ============

  /// Request Curriculum Change via AI Chat
  Future<WorkoutCurriculum?> chatForCurriculum({
    required String userMessage,
    required UserProfile profile,
    required List<WorkoutTask> availableWorkouts,
  }) async {
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
If the user asks for a specific body part (하체, 상체, 코어, etc.), select exercises from that category.
Output JSON only.
''';

      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
        systemInstruction: Content.system(_curriculumSystemInstruction),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final jsonText = response.text;

      if (jsonText == null) return null;

      final jsonData = json.decode(jsonText) as Map<String, dynamic>;

      final workoutIds =
          (jsonData['workout_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final adjustments =
          jsonData['adjustments'] as Map<String, dynamic>? ?? {};

      final selectedTasks = <WorkoutTask>[];
      for (final id in workoutIds) {
        final task = availableWorkouts.firstWhere(
          (t) => t.id == id,
          orElse: () => availableWorkouts.first,
        );

        if (adjustments.containsKey(id)) {
          final adj = adjustments[id] as Map<String, dynamic>;
          task.applyAdjustment(
            newReps: adj['reps'] as int?,
            newSets: adj['sets'] as int?,
          );
        }

        selectedTasks.add(task);
      }

      return WorkoutCurriculum(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: jsonData['curriculum_title'] ?? '맞춤 운동',
        description: jsonData['curriculum_description'] ?? '',
        thumbnail: '',
        workoutTaskList: selectedTasks,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error in chat curriculum: $e');
      return null;
    }
  }

  // ============ AI Interview ============

  ChatSession? _interviewSession;

  /// Start Interview Session
  Future<String?> startInterviewChat(UserProfile profile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
        systemInstruction: Content.system(_interviewSystemInstruction),
      );

      _interviewSession = model.startChat();

      // Send user info via initial prompt
      final initialPrompt =
          '''
TASK: START_INTERVIEW

User Profile:
- Age: ${profile.age}
- Injury History: ${profile.injuryHistory.isEmpty ? "없음" : profile.injuryHistory}
- Goal: ${profile.goal.isEmpty ? "미정" : profile.goal}
- Experience Level: ${profile.experienceLevel}
- Target Exercise: ${profile.targetExercise}

Please start the interview in Korean.
''';

      final response = await _interviewSession!.sendMessage(
        Content.text(initialPrompt),
      );

      return response.text;
    } catch (e) {
      debugPrint('Error starting interview: $e');
      return null;
    }
  }

  /// Send Interview Message and Receive Response
  Future<InterviewResponse> sendInterviewMessage(String userMessage) async {
    if (_interviewSession == null) {
      return InterviewResponse(message: '인터뷰 세션이 없습니다.', isComplete: false);
    }

    try {
      final response = await _interviewSession!.sendMessage(
        Content.text(userMessage),
      );

      final responseText = response.text ?? '';

      // Check for JSON inclusion (When interview complete)
      if (responseText.contains('"interview_complete": true') ||
          responseText.contains('"interview_complete":true')) {
        // Extract JSON
        final jsonMatch = RegExp(
          r'\{[\s\S]*"interview_complete"[\s\S]*\}',
        ).firstMatch(responseText);

        if (jsonMatch != null) {
          try {
            final jsonData =
                json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;
            return InterviewResponse(
              message: responseText,
              isComplete: true,
              summaryText: jsonData['summary_text'] as String?,
              extractedDetails: jsonData['extracted_details'] != null
                  ? Map<String, String>.from(
                      (jsonData['extracted_details'] as Map).map(
                        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
                      ),
                    )
                  : null,
            );
          } catch (e) {
            debugPrint('JSON parse error: $e');
          }
        }
      }

      return InterviewResponse(message: responseText, isComplete: false);
    } catch (e) {
      debugPrint('Error sending interview message: $e');

      // Handle the specific "Unhandled format for Content: {}" error
      if (e.toString().contains('Unhandled format for Content')) {
        return InterviewResponse(
          message: '대화 내용 형식이 올바르지 않습니다. 인터뷰를 다시 시작해주세요.',
          isComplete: false,
          hasError: true,
        );
      }

      return InterviewResponse(
        message: '오류가 발생했습니다. 다시 시도해주세요.',
        isComplete: false,
        hasError: true,
      );
    }
  }

  /// Send Chat Message with Image (One-off or Session?)
  /// Treated as one-off analysis for simplicity, or can be included in session.
  /// google_generative_ai package supports images in multi-turn chat.
  Future<InterviewResponse> chatWithImage({
    required String userMessage,
    required File imageFile,
    required UserProfile profile,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
        systemInstruction: Content.system(_consultantSystemInstruction),
      );

      final imageBytes = await imageFile.readAsBytes();
      final prompt = Content.multi([
        TextPart('''
User Profile:
- Age: ${profile.age}
- Injury History: ${profile.injuryHistory}
- Goal: ${profile.goal}
- Experience Level: ${profile.experienceLevel}

The user has uploaded an image related to their workout or physical condition.
Analyze the image and the user's message providing professional fitness advice.
User Message: "$userMessage"
'''),
        DataPart('image/jpeg', imageBytes), // Assuming JPEG or detecting mime?
      ]);

      final response = await model.generateContent([prompt]);
      return InterviewResponse(
        message: response.text ?? '죄송합니다. 사진을 분석할 수 없습니다.',
        isComplete: false,
      );
    } catch (e) {
      debugPrint('Error chatting with image: $e');
      return InterviewResponse(
        message: '사진 분석 중 오류가 발생했습니다: $e',
        isComplete: false,
        hasError: true,
      );
    }
  }

  /// End Interview Session
  void endInterviewSession() {
    _interviewSession = null;
  }

  // ============ Fall Detection Analysis ============

  /// Analyze Fall Detection
  Future<bool> analyzeFallDetection({
    required File videoFile,
    required UserProfile profile,
  }) async {
    try {
      final uri = await _uploadFile(videoFile);
      if (uri == null) return false;

      await Future.delayed(const Duration(seconds: 2));

      final endpoint = Uri.parse('$_generateUrl?key=$_apiKey');

      final body = json.encode({
        'contents': [
          {
            'parts': [
              {
                'text': '''
Analyze this video for potential fall detection.

User may have fallen during exercise. Check if:
1. The person appears to have lost balance and fallen to the ground
2. The person is motionless on the ground
3. This is NOT a normal exercise position (like plank or floor exercise)

Respond with JSON:
{
  "is_fall_detected": Boolean,
  "confidence": Float (0-1),
  "description": "String (Korean)"
}
''',
              },
              {
                'file_data': {'mime_type': 'video/mp4', 'file_uri': uri},
              },
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      });

      final response = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) {
          final result = json.decode(text);
          return result['is_fall_detected'] == true &&
              (result['confidence'] ?? 0) > 0.7;
        }
      }
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
    try {
      final analysesText = setAnalyses
          .asMap()
          .entries
          .map((e) => 'Set ${e.key + 1}: ${json.encode(e.value)}')
          .join('\n');

      final prompt =
          '''
User Profile: ${profile.toJson()}

All Set Analyses:
$analysesText

Generate a final workout session report in Korean. Include:
1. Overall performance summary
2. Key improvements made during the session
3. Areas needing improvement
4. Recommendations for next session

Output as plain text (Korean), not JSON.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      debugPrint('Error generating final report: $e');
      return null;
    }
  }
}

/// 인터뷰 응답 모델
class InterviewResponse {
  final String message;
  final bool isComplete;
  final String? summaryText;
  final Map<String, String>? extractedDetails;
  final bool hasError;

  InterviewResponse({
    required this.message,
    required this.isComplete,
    this.summaryText,
    this.extractedDetails,
    this.hasError = false,
  });
}
