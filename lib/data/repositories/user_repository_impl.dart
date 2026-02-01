import 'package:dartz/dartz.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/local/user_local_datasource.dart';
import '../models/user_profile_model.dart';

/// Implementation of UserRepository
class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, UserProfile?>> getUserProfile() async {
    try {
      final model = await localDataSource.getUserProfile();
      if (model != null) {
        return Right(model.toEntity());
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to load user profile: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveUserProfile(UserProfile profile) async {
    try {
      final model = UserProfileModel.fromEntity(profile);
      await localDataSource.saveUserProfile(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save user profile: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateUserProfile(
    UserProfile profile,
  ) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
      final model = UserProfileModel.fromEntity(updatedProfile);
      await localDataSource.saveUserProfile(model);
      return Right(updatedProfile);
    } catch (e) {
      return Left(CacheFailure('Failed to update user profile: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUserProfile() async {
    try {
      await localDataSource.deleteUserProfile();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete user profile: $e'));
    }
  }
}
