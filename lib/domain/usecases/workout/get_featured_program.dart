import 'package:dartz/dartz.dart';

import '../../entities/featured_program.dart';
import '../../repositories/workout_repository.dart';
import '../../../core/error/failures.dart';

/// Use case to get featured program
class GetFeaturedProgramUseCase {
  final WorkoutRepository repository;

  GetFeaturedProgramUseCase(this.repository);

  Future<Either<Failure, FeaturedProgram?>> execute([String? category]) async {
    return await repository.getFeaturedProgram(category);
  }
}
