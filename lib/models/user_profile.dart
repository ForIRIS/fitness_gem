import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String age;
  String injuryHistory;
  String goal;
  String experienceLevel;
  String targetExercise; // e.g., "Squat"
  String? nickname; // Nickname (Optional)
  String userTier; // 'free', 'basic', 'premium' (Default: 'free')
  String? guardianPhone; // Guardian contact (Optional)
  bool fallDetectionEnabled; // Whether to use fall detection

  // AI Interview Result Fields
  String? interviewSummary; // AI interview summary
  Map<String, String>? extractedDetails; // Detailed extracted info
  DateTime? lastInterviewDate; // Last interview date

  UserProfile({
    required this.age,
    required this.injuryHistory,
    required this.goal,
    required this.experienceLevel,
    required this.targetExercise,
    this.nickname,
    this.userTier = 'free',
    this.guardianPhone,
    this.fallDetectionEnabled = false, // Default disabled (Optional)
    this.interviewSummary,
    this.extractedDetails,
    this.lastInterviewDate,
  });

  /// Convenience method for saving instance
  Future<void> save() => UserProfile.saveProfile(this);

  /// Check if 7 days have passed - Whether re-interview is possible
  bool get canReinterview {
    if (lastInterviewDate == null) return true;
    final daysSinceInterview = DateTime.now()
        .difference(lastInterviewDate!)
        .inDays;
    return daysSinceInterview >= 7;
  }

  /// Days remaining until the next interview is possible
  int get daysUntilReinterview {
    if (lastInterviewDate == null) return 0;
    final daysSinceInterview = DateTime.now()
        .difference(lastInterviewDate!)
        .inDays;
    return (7 - daysSinceInterview).clamp(0, 7);
  }

  /// Display name ('Trainee' if no nickname)
  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : 'Trainee';

  /// For tier display (UI)
  String get displayTier => userTier.toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'injuryHistory': injuryHistory,
      'goal': goal,
      'experienceLevel': experienceLevel,
      'targetExercise': targetExercise,
      'nickname': nickname,
      'userTier': userTier,
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
      nickname: map['nickname'],
      userTier: map['userTier'] ?? 'free',
      guardianPhone: map['guardianPhone'],
      fallDetectionEnabled: map['fallDetectionEnabled'] ?? false,
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
