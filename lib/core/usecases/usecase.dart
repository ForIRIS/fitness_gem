import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base class for all use cases
///
/// Type: Return type of the use case
/// Params: Parameters required by the use case
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> execute(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> execute();
}
