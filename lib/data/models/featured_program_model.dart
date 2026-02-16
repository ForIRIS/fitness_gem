import 'dart:convert';
import '../../domain/entities/featured_program.dart';

import 'workout_curriculum_model.dart';

/// Data model for FeaturedProgram
class FeaturedProgramModel {
  final String id;
  final String title;
  final String slogan;
  final String description;
  final String imageUrl;
  final String membersCount;
  final double rating;
  final String difficulty;
  final List<String> userAvatars;
  final WorkoutCurriculumModel? workoutCurriculum;

  const FeaturedProgramModel({
    required this.id,
    required this.title,
    required this.slogan,
    required this.description,
    required this.imageUrl,
    required this.membersCount,
    required this.rating,
    required this.difficulty,
    required this.userAvatars,
    this.workoutCurriculum,
  });

  /// Convert to domain entity
  FeaturedProgram toEntity() {
    return FeaturedProgram(
      id: id,
      title: title,
      slogan: slogan,
      description: description,
      imageUrl: imageUrl,
      membersCount: membersCount,
      rating: rating,
      difficulty: difficulty,
      userAvatars: userAvatars,
      workoutCurriculum: workoutCurriculum?.toEntity(),
    );
  }

  /// Create from domain entity
  factory FeaturedProgramModel.fromEntity(FeaturedProgram entity) {
    return FeaturedProgramModel(
      id: entity.id,
      title: entity.title,
      slogan: entity.slogan,
      description: entity.description,
      imageUrl: entity.imageUrl,
      membersCount: entity.membersCount,
      rating: entity.rating,
      difficulty: entity.difficulty,
      userAvatars: entity.userAvatars,
      workoutCurriculum: entity.workoutCurriculum != null
          ? WorkoutCurriculumModel.fromEntity(entity.workoutCurriculum!)
          : null,
    );
  }

  /// Create from JSON map
  factory FeaturedProgramModel.fromMap(Map<String, dynamic> map) {
    return FeaturedProgramModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      slogan: map['slogan']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      membersCount: map['membersCount']?.toString() ?? '0',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      difficulty: map['difficulty']?.toString() ?? '1',
      userAvatars:
          (map['userAvatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      workoutCurriculum: map['workoutCurriculum'] != null
          ? WorkoutCurriculumModel.fromMap(
              Map<String, dynamic>.from(map['workoutCurriculum']),
            )
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'slogan': slogan,
      'description': description,
      'imageUrl': imageUrl,
      'membersCount': membersCount,
      'rating': rating,
      'difficulty': difficulty,
      'userAvatars': userAvatars,
      if (workoutCurriculum != null)
        'workoutCurriculum': workoutCurriculum!.toMap(),
    };
  }

  String toJson() => json.encode(toMap());

  factory FeaturedProgramModel.fromJson(String source) =>
      FeaturedProgramModel.fromMap(json.decode(source));
}
