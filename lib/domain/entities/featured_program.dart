import 'package:equatable/equatable.dart';
import 'workout_curriculum.dart';

/// Featured Program Entity
///
/// Represents a highlighted workout program on the home screen.
/// Contains both the executable curriculum and UI metadata.
class FeaturedProgram extends Equatable {
  final String id;
  final String title;
  final String slogan;
  final String description;
  final String imageUrl;
  final String membersCount;
  final double rating;
  final String difficulty;
  final List<String> userAvatars;
  final WorkoutCurriculum? workoutCurriculum;

  const FeaturedProgram({
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

  @override
  List<Object?> get props => [
    id,
    title,
    slogan,
    description,
    imageUrl,
    membersCount,
    rating,
    difficulty,
    userAvatars,
    workoutCurriculum,
  ];
}
