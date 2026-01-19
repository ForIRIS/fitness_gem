import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';
import '../models/workout_task.dart';
import '../models/workout_curriculum.dart';

/// GeminiService - Gemini AI 통합 서비스
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
    _initializeApiKey();
  }

  /// API 키 초기화
  Future<void> _initializeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_apiKeyPrefKey);

    if (savedKey != null && savedKey.isNotEmpty) {
      _apiKey = savedKey;
    } else {
      _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    }
    _initModel();
  }

  /// 모델 초기화
  void _initModel() {
    if (_apiKey.isEmpty) return;

    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
      systemInstruction: Content.system(_analysisSystemInstruction),
    );
  }

  /// API 키 변경
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

  /// 현재 유효한 API 키 조회 (내부 사용용)
  Future<String> getApiKey() async {
    if (_apiKey.isNotEmpty) return _apiKey;

    // 재확인
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPrefKey) ??
        dotenv.env['GEMINI_API_KEY'] ??
        '';
  }

  /// UI 표시용 사용자 설정 키 조회 (설정 화면용)
  Future<String> getUserApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPrefKey) ?? '';
  }

  // 시스템 인스트럭션 - 운동 분석용
  static const String _analysisSystemInstruction = '''
**ROLE & OBJECTIVE**
You are "CoreFit AI," an advanced Biomechanics Analysis Engine. Your goal is to analyze fitness movements using a "Dual-Stream Vision Protocol" to provide real-time form correction and adaptive curriculum adjustments.

**INPUT DATA CONTEXT**
You will receive three types of data for each session:
1.  **USER PROFILE**: {Age, Injury History, Goal, Experience Level}. *Use this to adjust strictness (e.g., be stricter with injury history).*
2.  **SOURCE A (Raw Video/Image)**: Real-world footage. *Use for: Facial expression (Effort/Pain), Breathing, Tempo, Environment.*
3.  **SOURCE B (Skeleton/Depth Map)**: High-contrast geometric representation. *Use for: GROUND TRUTH for joint angles and alignment.*

**DUAL-STREAM PRIORITY LOGIC (The "X-Ray" Rule)**
1.  **Geometric Truth**: Always prioritize **Source B** for structural analysis.
2.  **Contextual Layering**: Use Source A to judge "Effort Level" (RPE).
3.  **Conflict Resolution**: If inputs conflict, **Source B is the authority** for body mechanics.

**CRITICAL SAFETY PROTOCOLS (Immediate Stop)**
Set `"safety_flag": true` and `"stop_reason": "..."` immediately if:
- **Pain**: Sudden grimacing or grabbing a body part (Source A).
- **Structure**: Lumbar flexion > 20° under load, or Knee Valgus > 15° (Source B).
- **Control**: Loss of balance or falling.

**OUTPUT FORMAT RULES**
- **Format**: JSON only. No Markdown code blocks.
- **Language**: JSON Keys in **English**, Values in **Korean** (for UI display).
- **Tone**: Professional, encouraging, and concise (TTS-friendly).

**JSON SCHEMA (Strict Adherence)**
{
  "session_summary": {
    "exercise_name": "String",
    "total_score": Integer (0-100),
    "safety_flag": Boolean,
    "stop_reason": "String (or null)"
  },
  "reasoning_trace": {
    "source_a_observation": "String",
    "source_b_observation": "String",
    "synthesis_logic": "String"
  },
  "feedback": {
    "main_issue": "String",
    "tts_message": "String"
  },
  "segments_analysis": [
    {
      "timestamp": Float,
      "issue": "String",
      "correction": "String"
    }
  ],
  "adaptive_curriculum": {
    "decision": "String (Increase / Maintain / Decrease / Recovery)",
    "next_plan": {
      "weight": "String",
      "reps": "String",
      "tempo": "String",
      "reason": "String"
    }
  }
}
''';

  // 시스템 인스트럭션 - 커리큘럼 생성용
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

  // 시스템 인스트럭션 - AI 인터뷰용
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

  // ============ 커리큘럼 생성 ============

  /// 커리큘럼 생성
  Future<WorkoutCurriculum?> generateCurriculum({
    required UserProfile profile,
    required String category,
    required List<WorkoutTask> availableWorkouts,
  }) async {
    try {
      // Gemini에 전달할 운동 목록 텍스트 생성
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

      // 선택된 운동 ID로 WorkoutTask 찾기
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

        // Gemini가 조정한 reps/sets 적용
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

  // ============ 영상 분석 (HTTP 파일 업로드 방식) ============

  /// 비디오 분석 (Source A: RGB, Source B: ControlNet)
  Future<Map<String, dynamic>?> analyzeVideoSession({
    required File rgbVideoFile,
    required File controlNetVideoFile,
    required UserProfile profile,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    bool isLastSet = false,
  }) async {
    try {
      // 1. 두 비디오 업로드
      debugPrint('Uploading RGB video...');
      final rgbUri = await _uploadFile(rgbVideoFile);
      if (rgbUri == null) return null;

      debugPrint('Uploading ControlNet video...');
      final controlNetUri = await _uploadFile(controlNetVideoFile);
      if (controlNetUri == null) return null;

      // 2. 비디오 처리 대기
      await Future.delayed(const Duration(seconds: 3));

      // 3. 분석 요청
      debugPrint('Requesting analysis...');
      return await _generateContentWithVideos(
        rgbUri: rgbUri,
        controlNetUri: controlNetUri,
        profile: profile,
        exerciseName: exerciseName,
        setNumber: setNumber,
        totalSets: totalSets,
        isLastSet: isLastSet,
      );
    } catch (e) {
      debugPrint('Error in video analysis: $e');
      return null;
    }
  }

  /// 파일 업로드
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

  /// 비디오 분석 요청
  Future<Map<String, dynamic>?> _generateContentWithVideos({
    required String rgbUri,
    required String controlNetUri,
    required UserProfile profile,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    bool isLastSet = false,
  }) async {
    try {
      final uri = Uri.parse('$_generateUrl?key=$_apiKey');

      final additionalInstructions = isLastSet
          ? '\nThis is the LAST set. Please also provide a final session summary and recommendations for the next workout.'
          : '';

      final body = json.encode({
        'systemInstruction': {
          'parts': [
            {'text': _analysisSystemInstruction},
          ],
        },
        'contents': [
          {
            'parts': [
              {
                'text':
                    '''
User Profile: ${profile.toJson()}
Exercise: $exerciseName
Current Set: $setNumber / $totalSets
$additionalInstructions

The first video (Source A) is the RGB footage showing the user's actual appearance.
The second video (Source B) is the ControlNet skeleton visualization - use this as GROUND TRUTH for joint analysis.

Analyze this workout set and provide feedback in JSON format.
''',
              },
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
          'temperature': 0.3,
          'responseMimeType': 'application/json',
        },
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) {
          return json.decode(text);
        }
      } else {
        debugPrint('Analysis failed: ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('Analysis error: $e');
      return null;
    }
  }

  // ============ AI 상담 (채팅) ============

  /// AI 상담으로 커리큘럼 변경 요청
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

  // ============ AI 인터뷰 ============

  ChatSession? _interviewSession;

  /// 인터뷰 세션 시작
  Future<String?> startInterviewChat(UserProfile profile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
        systemInstruction: Content.system(_interviewSystemInstruction),
      );

      _interviewSession = model.startChat();

      // 초기 프롬프트로 사용자 정보 전달
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

  /// 인터뷰 메시지 전송 및 응답 받기
  Future<InterviewResponse> sendInterviewMessage(String userMessage) async {
    if (_interviewSession == null) {
      return InterviewResponse(message: '인터뷰 세션이 없습니다.', isComplete: false);
    }

    try {
      final response = await _interviewSession!.sendMessage(
        Content.text(userMessage),
      );

      final responseText = response.text ?? '';

      // JSON 포함 여부 확인 (인터뷰 완료 시)
      if (responseText.contains('"interview_complete": true') ||
          responseText.contains('"interview_complete":true')) {
        // JSON 추출
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
      return InterviewResponse(
        message: '오류가 발생했습니다. 다시 시도해주세요.',
        isComplete: false,
        hasError: true,
      );
    }
  }

  /// 인터뷰 세션 종료
  void endInterviewSession() {
    _interviewSession = null;
  }

  // ============ 낙상 감지 분석 ============

  /// 낙상 상황 분석
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
