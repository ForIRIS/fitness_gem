import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';

class SetApiKeyUseCase implements UseCase<void, String> {
  final AIRepository repository;

  SetApiKeyUseCase(this.repository);

  @override
  Future<Either<Failure, void>> execute(String apiKey) async {
    try {
      await repository.setApiKey(apiKey);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save API Key: $e'));
    }
  }
}
