import 'package:dartz/dartz.dart';
import '../../repositories/workout_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

/// Use case to get daily hot categories
class GetDailyHotCategoriesUseCase implements NoParamsUseCase<List<String>> {
  final WorkoutRepository repository;

  GetDailyHotCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> execute() async {
    return await repository.getDailyHotCategories();
  }
}
