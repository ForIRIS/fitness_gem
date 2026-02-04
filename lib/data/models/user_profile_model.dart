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
  final String? guardianEmail;
  final String? emergencyMethod;
  final bool fallDetectionEnabled;
  final String? interviewSummary;
  final Map<String, String>? extractedDetails;
  final DateTime? lastInterviewDate;
  final double? stabilityBaseline;
  final double? mobilityScore;
  final String? baselineAnalysis;
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
    this.guardianEmail,
    this.emergencyMethod,
    this.fallDetectionEnabled = false,
    this.interviewSummary,
    this.extractedDetails,
    this.lastInterviewDate,
    this.stabilityBaseline,
    this.mobilityScore,
    this.baselineAnalysis,
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
      guardianEmail: guardianEmail,
      emergencyMethod: emergencyMethod,
      fallDetectionEnabled: fallDetectionEnabled,
      interviewSummary: interviewSummary,
      extractedDetails: extractedDetails,
      lastInterviewDate: lastInterviewDate,
      stabilityBaseline: stabilityBaseline,
      mobilityScore: mobilityScore,
      baselineAnalysis: baselineAnalysis,
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
      guardianEmail: entity.guardianEmail,
      emergencyMethod: entity.emergencyMethod,
      fallDetectionEnabled: entity.fallDetectionEnabled,
      interviewSummary: entity.interviewSummary,
      extractedDetails: entity.extractedDetails,
      lastInterviewDate: entity.lastInterviewDate,
      stabilityBaseline: entity.stabilityBaseline,
      mobilityScore: entity.mobilityScore,
      baselineAnalysis: entity.baselineAnalysis,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create from JSON map
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] ?? '',
      nickname: map['nickname'] ?? '',
      age: _parseInt(map['age']),
      gender: map['gender'] ?? '',
      height: _toDouble(map['height']),
      weight: _toDouble(map['weight']),
      fitnessLevel: map['fitnessLevel'] ?? '',
      targetExercise: map['targetExercise'] ?? '',
      healthConditions: map['healthConditions'] ?? '',
      goal: map['goal'] ?? '',
      userTier: map['userTier'] ?? 'free',
      guardianPhone: map['guardianPhone'],
      guardianEmail: map['guardianEmail'],
      emergencyMethod: map['emergencyMethod'],
      fallDetectionEnabled: map['fallDetectionEnabled'] ?? false,
      interviewSummary: map['interviewSummary'],
      extractedDetails: map['extractedDetails'] != null
          ? Map<String, String>.from(map['extractedDetails'])
          : null,
      lastInterviewDate: map['lastInterviewDate'] != null
          ? DateTime.parse(map['lastInterviewDate'])
          : null,
      stabilityBaseline: _toDouble(map['stabilityBaseline']),
      mobilityScore: _toDouble(map['mobilityScore']),
      baselineAnalysis: map['baselineAnalysis'],
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
      'guardianEmail': guardianEmail,
      'emergencyMethod': emergencyMethod,
      'fallDetectionEnabled': fallDetectionEnabled,
      'interviewSummary': interviewSummary,
      'extractedDetails': extractedDetails,
      'lastInterviewDate': lastInterviewDate?.toIso8601String(),
      'stabilityBaseline': stabilityBaseline,
      'mobilityScore': mobilityScore,
      'baselineAnalysis': baselineAnalysis,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  factory UserProfileModel.fromJson(String source) =>
      UserProfileModel.fromMap(json.decode(source));

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
