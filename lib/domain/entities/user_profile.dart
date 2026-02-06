import 'package:equatable/equatable.dart';

/// Domain Entity: UserProfile
/// Pure business object representing user information
class UserProfile extends Equatable {
  final String id;
  final String nickname;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String? profilePhotoPath; // Local path to profile photo
  final String fitnessLevel; // Also used as experienceLevel
  final String targetExercise;
  final String healthConditions; // Also used as injuryHistory
  final String goal;
  final String userTier; // 'free', 'basic', 'premium'
  final String? guardianPhone;
  final String? guardianEmail; // Added for Push Notification
  final String? emergencyMethod; // 'sms' or 'push'
  final bool fallDetectionEnabled;
  final String? interviewSummary;
  final Map<String, String>? extractedDetails;
  final DateTime? lastInterviewDate;
  final double? stabilityBaseline;
  final double? mobilityScore;
  final String? baselineAnalysis;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.nickname,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    this.profilePhotoPath,
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

  factory UserProfile.empty() {
    return UserProfile(
      id: '',
      nickname: '',
      age: 0,
      gender: '',
      height: 0,
      weight: 0,
      fitnessLevel: '',
      targetExercise: '',
      healthConditions: '',
      goal: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Convenience getters for compatibility with old model
  String get injuryHistory => healthConditions;
  String get experienceLevel => fitnessLevel;
  String get displayName => nickname.isNotEmpty ? nickname : 'Trainee';
  String get displayTier => userTier.toUpperCase();

  // Business logic

  /// Calculate BMI
  double get bmi {
    if (height <= 0) return 0;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  /// Get fitness level display name
  String get fitnessLevelDisplay {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return fitnessLevel;
    }
  }

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

  /// Serialization for API/storage (via data models)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'profilePhotoPath': profilePhotoPath,
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

  /// For GeminiService compatibility
  Map<String, dynamic> toJson() => toMap();

  /// Copy with method for updates
  UserProfile copyWith({
    String? id,
    String? nickname,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? profilePhotoPath,
    String? fitnessLevel,
    String? targetExercise,
    String? healthConditions,
    String? goal,
    String? userTier,
    String? guardianPhone,
    String? guardianEmail,
    String? emergencyMethod,
    bool? fallDetectionEnabled,
    String? interviewSummary,
    Map<String, String>? extractedDetails,
    DateTime? lastInterviewDate,
    double? stabilityBaseline,
    double? mobilityScore,
    String? baselineAnalysis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      targetExercise: targetExercise ?? this.targetExercise,
      healthConditions: healthConditions ?? this.healthConditions,
      goal: goal ?? this.goal,
      userTier: userTier ?? this.userTier,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      emergencyMethod: emergencyMethod ?? this.emergencyMethod,
      fallDetectionEnabled: fallDetectionEnabled ?? this.fallDetectionEnabled,
      interviewSummary: interviewSummary ?? this.interviewSummary,
      extractedDetails: extractedDetails ?? this.extractedDetails,
      lastInterviewDate: lastInterviewDate ?? this.lastInterviewDate,
      stabilityBaseline: stabilityBaseline ?? this.stabilityBaseline,
      mobilityScore: mobilityScore ?? this.mobilityScore,
      baselineAnalysis: baselineAnalysis ?? this.baselineAnalysis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nickname,
    age,
    gender,
    height,
    weight,
    profilePhotoPath,
    fitnessLevel,
    targetExercise,
    healthConditions,
    goal,
    userTier,
    guardianPhone,
    guardianEmail,
    emergencyMethod,
    fallDetectionEnabled,
    interviewSummary,
    extractedDetails,
    lastInterviewDate,
    stabilityBaseline,
    mobilityScore,
    baselineAnalysis,
    createdAt,
    updatedAt,
  ];
}
