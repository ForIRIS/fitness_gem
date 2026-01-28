import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// SetAnalysis - Analysis results for an individual set
class SetAnalysis {
  final int setNumber;
  final int score;
  final String mainIssue;
  final String ttsMessage;
  final List<SegmentIssue> segments;
  final AdaptiveCurriculum? adaptiveCurriculum;

  SetAnalysis({
    required this.setNumber,
    required this.score,
    required this.mainIssue,
    required this.ttsMessage,
    required this.segments,
    this.adaptiveCurriculum,
  });

  factory SetAnalysis.fromGeminiResponse(
    int setNumber,
    Map<String, dynamic> response,
  ) {
    final sessionSummary = response['session_summary'] ?? {};
    final feedback = response['feedback'] ?? {};
    final segmentsData = response['segments_analysis'] as List<dynamic>? ?? [];
    final adaptiveData = response['adaptive_curriculum'];

    return SetAnalysis(
      setNumber: setNumber,
      score: sessionSummary['total_score'] ?? 0,
      mainIssue: feedback['main_issue'] ?? '',
      ttsMessage: feedback['tts_message'] ?? '',
      segments: segmentsData
          .map((s) => SegmentIssue.fromMap(s as Map<String, dynamic>))
          .toList(),
      adaptiveCurriculum: adaptiveData != null
          ? AdaptiveCurriculum.fromMap(adaptiveData)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'score': score,
      'mainIssue': mainIssue,
      'ttsMessage': ttsMessage,
      'segments': segments.map((s) => s.toMap()).toList(),
      'adaptiveCurriculum': adaptiveCurriculum?.toMap(),
    };
  }

  factory SetAnalysis.fromMap(Map<String, dynamic> map) {
    return SetAnalysis(
      setNumber: map['setNumber'] ?? 0,
      score: map['score'] ?? 0,
      mainIssue: map['mainIssue'] ?? '',
      ttsMessage: map['ttsMessage'] ?? '',
      segments:
          (map['segments'] as List<dynamic>?)
              ?.map((s) => SegmentIssue.fromMap(s))
              .toList() ??
          [],
      adaptiveCurriculum: map['adaptiveCurriculum'] != null
          ? AdaptiveCurriculum.fromMap(map['adaptiveCurriculum'])
          : null,
    );
  }
}

/// SegmentIssue - Issues per segment
class SegmentIssue {
  final double timestamp;
  final String issue;
  final String correction;

  SegmentIssue({
    required this.timestamp,
    required this.issue,
    required this.correction,
  });

  factory SegmentIssue.fromMap(Map<String, dynamic> map) {
    return SegmentIssue(
      timestamp: (map['timestamp'] ?? 0.0).toDouble(),
      issue: map['issue'] ?? '',
      correction: map['correction'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'timestamp': timestamp, 'issue': issue, 'correction': correction};
  }
}

/// AdaptiveCurriculum - Adaptive curriculum adjustments
class AdaptiveCurriculum {
  final String decision; // Increase, Maintain, Decrease, Recovery
  final String? weight;
  final String? reps;
  final String? tempo;
  final String? reason;

  AdaptiveCurriculum({
    required this.decision,
    this.weight,
    this.reps,
    this.tempo,
    this.reason,
  });

  factory AdaptiveCurriculum.fromMap(Map<String, dynamic> map) {
    final nextPlan = map['next_plan'] as Map<String, dynamic>? ?? {};
    return AdaptiveCurriculum(
      decision: map['decision'] ?? 'Maintain',
      weight: nextPlan['weight'],
      reps: nextPlan['reps'],
      tempo: nextPlan['tempo'],
      reason: nextPlan['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'decision': decision,
      'next_plan': {
        'weight': weight,
        'reps': reps,
        'tempo': tempo,
        'reason': reason,
      },
    };
  }
}

/// SessionAnalysis - Analysis results for the entire session
class SessionAnalysis {
  final String sessionId;
  final String curriculumId;
  final DateTime date;
  final int totalScore;
  final double? caloriesBurned;
  final List<TaskAnalysis> taskAnalyses;
  final String? finalReport;

  SessionAnalysis({
    required this.sessionId,
    required this.curriculumId,
    required this.date,
    required this.totalScore,
    this.caloriesBurned,
    required this.taskAnalyses,
    this.finalReport,
  });

  factory SessionAnalysis.fromMap(Map<String, dynamic> map) {
    return SessionAnalysis(
      sessionId: map['sessionId'] ?? '',
      curriculumId: map['curriculumId'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      totalScore: map['totalScore'] ?? 0,
      caloriesBurned: map['caloriesBurned']?.toDouble(),
      taskAnalyses:
          (map['taskAnalyses'] as List<dynamic>?)
              ?.map((t) => TaskAnalysis.fromMap(t))
              .toList() ??
          [],
      finalReport: map['finalReport'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'curriculumId': curriculumId,
      'date': date.toIso8601String(),
      'totalScore': totalScore,
      'caloriesBurned': caloriesBurned,
      'taskAnalyses': taskAnalyses.map((t) => t.toMap()).toList(),
      'finalReport': finalReport,
    };
  }

  String toJson() => json.encode(toMap());

  factory SessionAnalysis.fromJson(String source) =>
      SessionAnalysis.fromMap(json.decode(source));

  // Save to SharedPreferences (managed as history list)
  static const _key = 'session_history';
  static const _maxHistoryCount = 30;

  static Future<void> save(SessionAnalysis analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadAll();
    history.insert(0, analysis);

    // Maintain maximum 30 entries
    if (history.length > _maxHistoryCount) {
      history.removeRange(_maxHistoryCount, history.length);
    }

    final jsonList = history.map((a) => a.toJson()).toList();
    await prefs.setStringList(_key, jsonList);
  }

  static Future<List<SessionAnalysis>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.map((json) => SessionAnalysis.fromJson(json)).toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// TaskAnalysis - Analysis results for an individual exercise
class TaskAnalysis {
  final String taskId;
  final String taskTitle;
  final List<SetAnalysis> setAnalyses;
  final int averageScore;

  TaskAnalysis({
    required this.taskId,
    required this.taskTitle,
    required this.setAnalyses,
  }) : averageScore = setAnalyses.isEmpty
           ? 0
           : (setAnalyses.map((s) => s.score).reduce((a, b) => a + b) /
                     setAnalyses.length)
                 .round();

  factory TaskAnalysis.fromMap(Map<String, dynamic> map) {
    final setAnalysesList =
        (map['setAnalyses'] as List<dynamic>?)
            ?.map((s) => SetAnalysis.fromMap(s))
            .toList() ??
        [];

    return TaskAnalysis(
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      setAnalyses: setAnalysesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'setAnalyses': setAnalyses.map((s) => s.toMap()).toList(),
      'averageScore': averageScore,
    };
  }
}
