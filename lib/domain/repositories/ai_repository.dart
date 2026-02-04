import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../entities/workout_task.dart';
import '../entities/workout_curriculum.dart';
import '../entities/interview_response.dart';

abstract class AIRepository {
  /// Generate a workout curriculum based on profile and available workouts
  Future<Either<Failure, WorkoutCurriculum?>> generateCurriculum({
    required UserProfile profile,
    required String category,
    required List<WorkoutTask> availableWorkouts,
  });

  /// Chat with AI to adjust curriculum
  Future<Either<Failure, WorkoutCurriculum?>> chatForCurriculum({
    required String userMessage,
    required UserProfile profile,
    required List<WorkoutTask> availableWorkouts,
  });

  /// Generate a personalized curriculum from deep interview results
  Future<Either<Failure, WorkoutCurriculum?>>
  generateCurriculumFromInterviewResult({
    required UserProfile profile,
    required List<WorkoutTask> availableWorkouts,
    required Map<String, String> interviewDetails,
  });

  /// Analyze a workout video session (RGB + ControlNet)
  Future<Either<Failure, Map<String, dynamic>?>> analyzeVideoSession({
    required File rgbVideoFile,
    required File controlNetVideoFile,
    required UserProfile profile,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    bool isLastSet = false,
    String language = 'Korean',
  });

  /// Analyze fall detection video
  Future<Either<Failure, bool>> analyzeFallDetection({
    required File videoFile,
    required UserProfile profile,
  });

  /// Analyze baseline assessment video
  Future<Either<Failure, Map<String, dynamic>>> analyzeBaselineVideo(
    String videoPath,
  );

  /// Start an AI interview session
  Future<Either<Failure, String?>> startInterviewChat(UserProfile profile);

  /// Send a message in the interview session
  Future<Either<Failure, InterviewResponse>> sendInterviewMessage(
    String userMessage,
  );

  /// Management methods
  Future<void> setApiKey(String apiKey);
  Future<String> getApiKey();
}
