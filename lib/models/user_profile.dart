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

  UserProfile({
    required this.age,
    required this.injuryHistory,
    required this.goal,
    required this.experienceLevel,
    required this.targetExercise,
    this.guardianPhone,
    this.fallDetectionEnabled = true, // 기본값 활성화
  });

  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'injuryHistory': injuryHistory,
      'goal': goal,
      'experienceLevel': experienceLevel,
      'targetExercise': targetExercise,
      'guardianPhone': guardianPhone,
      'fallDetectionEnabled': fallDetectionEnabled,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));

  // Persistence Methods
  static const _key = 'user_profile';

  static Future<void> save(UserProfile profile) async {
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
