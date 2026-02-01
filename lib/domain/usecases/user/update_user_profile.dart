import 'package:dartz/dartz.dart';
import '../../entities/user_profile.dart';
import '../../repositories/user_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

/// Use case to update user profile
class UpdateUserProfileUseCase implements UseCase<UserProfile, UserProfile> {
  final UserRepository repository;

  UpdateUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile>> execute(UserProfile params) async {
    return await repository.updateUserProfile(params);
  }
}
