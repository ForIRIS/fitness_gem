// Failure classes for error handling

/// Base class for all failures in the application
abstract class Failure {
  final String message;

  const Failure(this.message);
}

/// Failure when server/remote operation fails
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Failure when cache/local operation fails
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

/// Failure when network is unavailable
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Failure when validation fails
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}

/// Failure when authentication fails
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}
