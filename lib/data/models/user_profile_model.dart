import 'dart:convert';
import '../../domain/entities/user_profile.dart';

/// Data model for UserProfile
/// Handles serialization/deserialization and mapping to domain entity
class UserProfileModel {
  final String id;
  final String nickname;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String fitnessLevel;
  final String targetExercise;
  final String healthConditions;
  final String goal;
  final String userTier;
  final String? guardianPhone;
  final bool fallDetectionEnabled;
  final String? interviewSummary;
  final Map<String, String>? extractedDetails;
  final DateTime? lastInterviewDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileModel({
    required this.id,
    required this.nickname,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.fitnessLevel,
    required this.targetExercise,
    required this.healthConditions,
    required this.goal,
    this.userTier = 'free',
    this.guardianPhone,
    this.fallDetectionEnabled = false,
    this.interviewSummary,
    this.extractedDetails,
    this.lastInterviewDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to domain entity
  UserProfile toEntity() {
    return UserProfile(
      id: id,
      nickname: nickname,
      age: age,
      gender: gender,
      height: height,
      weight: weight,
      fitnessLevel: fitnessLevel,
      targetExercise: targetExercise,
      healthConditions: healthConditions,
      goal: goal,
      userTier: userTier,
      guardianPhone: guardianPhone,
      fallDetectionEnabled: fallDetectionEnabled,
      interviewSummary: interviewSummary,
      extractedDetails: extractedDetails,
      lastInterviewDate: lastInterviewDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      nickname: entity.nickname,
      age: entity.age,
      gender: entity.gender,
      height: entity.height,
      weight: entity.weight,
      fitnessLevel: entity.fitnessLevel,
      targetExercise: entity.targetExercise,
      healthConditions: entity.healthConditions,
      goal: entity.goal,
      userTier: entity.userTier,
      guardianPhone: entity.guardianPhone,
      fallDetectionEnabled: entity.fallDetectionEnabled,
      interviewSummary: entity.interviewSummary,
      extractedDetails: entity.extractedDetails,
      lastInterviewDate: entity.lastInterviewDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create from JSON map
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] ?? '',
      nickname: map['nickname'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      height: (map['height'] ?? 0).toDouble(),
      weight: (map['weight'] ?? 0).toDouble(),
      fitnessLevel: map['fitnessLevel'] ?? '',
      targetExercise: map['targetExercise'] ?? '',
      healthConditions: map['healthConditions'] ?? '',
      goal: map['goal'] ?? '',
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
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'fitnessLevel': fitnessLevel,
      'targetExercise': targetExercise,
      'healthConditions': healthConditions,
      'goal': goal,
      'userTier': userTier,
      'guardianPhone': guardianPhone,
      'fallDetectionEnabled': fallDetectionEnabled,
      'interviewSummary': interviewSummary,
      'extractedDetails': extractedDetails,
      'lastInterviewDate': lastInterviewDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  factory UserProfileModel.fromJson(String source) =>
      UserProfileModel.fromMap(json.decode(source));
}
