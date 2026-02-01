import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';
import '../../entities/user_profile.dart';

class AnalyzeVideoSessionParams {
  final File rgbVideoFile;
  final File controlNetVideoFile;
  final UserProfile profile;
  final String exerciseName;
  final int setNumber;
  final int totalSets;
  final bool isLastSet;
  final String language;

  AnalyzeVideoSessionParams({
    required this.rgbVideoFile,
    required this.controlNetVideoFile,
    required this.profile,
    required this.exerciseName,
    required this.setNumber,
    required this.totalSets,
    this.isLastSet = false,
    this.language = 'Korean',
  });
}

class AnalyzeVideoSessionUseCase
    implements UseCase<Map<String, dynamic>?, AnalyzeVideoSessionParams> {
  final AIRepository repository;

  AnalyzeVideoSessionUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>?>> execute(
    AnalyzeVideoSessionParams params,
  ) async {
    return await repository.analyzeVideoSession(
      rgbVideoFile: params.rgbVideoFile,
      controlNetVideoFile: params.controlNetVideoFile,
      profile: params.profile,
      exerciseName: params.exerciseName,
      setNumber: params.setNumber,
      totalSets: params.totalSets,
      isLastSet: params.isLastSet,
      language: params.language,
    );
  }
}
