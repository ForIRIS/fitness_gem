import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';
import '../../entities/user_profile.dart';

class StartInterviewUseCase implements UseCase<String?, UserProfile> {
  final AIRepository repository;

  StartInterviewUseCase(this.repository);

  @override
  Future<Either<Failure, String?>> execute(UserProfile params) async {
    return await repository.startInterviewChat(params);
  }
}
