import 'package:dartz/dartz.dart';

import '../../entities/featured_program.dart';
import '../../repositories/workout_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

/// Use case to get featured program
class GetFeaturedProgramUseCase implements NoParamsUseCase<FeaturedProgram?> {
  final WorkoutRepository repository;

  GetFeaturedProgramUseCase(this.repository);

  @override
  Future<Either<Failure, FeaturedProgram?>> execute() async {
    return await repository.getFeaturedProgram();
  }
}
