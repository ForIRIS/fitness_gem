import 'package:dartz/dartz.dart';
import '../entities/user_profile.dart';
import '../../core/error/failures.dart';

/// Repository interface for user-related operations
///
/// This defines the contract that data layer must implement
abstract class UserRepository {
  /// Get user profile from local storage
  Future<Either<Failure, UserProfile?>> getUserProfile();

  /// Save user profile to local storage
  Future<Either<Failure, void>> saveUserProfile(UserProfile profile);

  /// Update user profile
  Future<Either<Failure, UserProfile>> updateUserProfile(UserProfile profile);

  /// Delete user profile
  Future<Either<Failure, void>> deleteUserProfile();
}
