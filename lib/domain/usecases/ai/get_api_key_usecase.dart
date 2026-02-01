import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';

class GetApiKeyUseCase implements NoParamsUseCase<String> {
  final AIRepository repository;

  GetApiKeyUseCase(this.repository);

  @override
  Future<Either<Failure, String>> execute() async {
    try {
      final apiKey = await repository.getApiKey();
      return Right(apiKey);
    } catch (e) {
      return Left(CacheFailure('Failed to get API Key: $e'));
    }
  }
}
