import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/ai_repository.dart';

class AnalyzeBaselineVideoUseCase {
  final AIRepository repository;

  AnalyzeBaselineVideoUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> execute(
    String videoPath,
  ) async {
    return await repository.analyzeBaselineVideo(videoPath);
  }
}
