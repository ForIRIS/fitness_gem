import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/user_repository.dart';

class DeleteUserProfileUseCase {
  final UserRepository repository;

  DeleteUserProfileUseCase(this.repository);

  Future<Either<Failure, void>> execute() {
    return repository.deleteUserProfile();
  }
}
