import 'package:dartz/dartz.dart';
import '../../entities/user_profile.dart';
import '../../repositories/user_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

/// Use case to get user profile
class GetUserProfileUseCase implements NoParamsUseCase<UserProfile?> {
  final UserRepository repository;

  GetUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile?>> execute() async {
    return await repository.getUserProfile();
  }
}
