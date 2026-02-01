import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';
import '../../entities/user_profile.dart';

class AnalyzeFallDetectionParams {
  final File videoFile;
  final UserProfile profile;

  AnalyzeFallDetectionParams({required this.videoFile, required this.profile});
}

class AnalyzeFallDetectionUseCase
    implements UseCase<bool, AnalyzeFallDetectionParams> {
  final AIRepository repository;

  AnalyzeFallDetectionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> execute(
    AnalyzeFallDetectionParams params,
  ) async {
    return await repository.analyzeFallDetection(
      videoFile: params.videoFile,
      profile: params.profile,
    );
  }
}
