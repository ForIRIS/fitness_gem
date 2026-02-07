import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';

/// Returns only the user-entered API key (for UI display)
/// Does NOT return fallback key from .env
class GetUserApiKeyUseCase implements NoParamsUseCase<String> {
  final AIRepository repository;

  GetUserApiKeyUseCase(this.repository);

  @override
  Future<Either<Failure, String>> execute() async {
    try {
      final apiKey = await repository.getUserApiKey();
      return Right(apiKey);
    } catch (e) {
      return Left(CacheFailure('Failed to get user API Key: $e'));
    }
  }
}
