import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String age;
  String injuryHistory;
  String goal;
  String experienceLevel;
  String targetExercise; // e.g., "Squat"
  String? guardianPhone; // 보호자 연락처 (선택)
  bool fallDetectionEnabled; // 낙상 감지 사용 여부

  // AI 인터뷰 결과 필드
  String? interviewSummary; // AI 인터뷰 요약
  Map<String, String>? extractedDetails; // 상세 추출 정보
  DateTime? lastInterviewDate; // 마지막 인터뷰 날짜

  UserProfile({
    required this.age,
    required this.injuryHistory,
    required this.goal,
    required this.experienceLevel,
    required this.targetExercise,
    this.guardianPhone,
    this.fallDetectionEnabled = true, // 기본값 활성화
    this.interviewSummary,
    this.extractedDetails,
    this.lastInterviewDate,
  });

  /// 인스턴스 저장 편의 메서드
  Future<void> save() => UserProfile.saveProfile(this);

  /// 7일 경과 여부 체크 - 재인터뷰 가능 여부
  bool get canReinterview {
    if (lastInterviewDate == null) return true;
    final daysSinceInterview = DateTime.now()
        .difference(lastInterviewDate!)
        .inDays;
    return daysSinceInterview >= 7;
  }

  /// 다음 인터뷰 가능 날짜까지 남은 일수
  int get daysUntilReinterview {
    if (lastInterviewDate == null) return 0;
    final daysSinceInterview = DateTime.now()
        .difference(lastInterviewDate!)
        .inDays;
    return (7 - daysSinceInterview).clamp(0, 7);
  }

  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'injuryHistory': injuryHistory,
      'goal': goal,
      'experienceLevel': experienceLevel,
      'targetExercise': targetExercise,
      'guardianPhone': guardianPhone,
      'fallDetectionEnabled': fallDetectionEnabled,
      'interviewSummary': interviewSummary,
      'extractedDetails': extractedDetails,
      'lastInterviewDate': lastInterviewDate?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      age: map['age'] ?? '',
      injuryHistory: map['injuryHistory'] ?? '',
      goal: map['goal'] ?? '',
      experienceLevel: map['experienceLevel'] ?? '',
      targetExercise: map['targetExercise'] ?? '',
      guardianPhone: map['guardianPhone'],
      fallDetectionEnabled: map['fallDetectionEnabled'] ?? true,
      interviewSummary: map['interviewSummary'],
      extractedDetails: map['extractedDetails'] != null
          ? Map<String, String>.from(map['extractedDetails'])
          : null,
      lastInterviewDate: map['lastInterviewDate'] != null
          ? DateTime.parse(map['lastInterviewDate'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));

  // Persistence Methods
  static const _key = 'user_profile';

  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, profile.toJson());
  }

  static Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      return UserProfile.fromJson(jsonString);
    }
    return null;
  }
}
