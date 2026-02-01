import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';
import '../../entities/interview_response.dart';

class SendInterviewMessageUseCase
    implements UseCase<InterviewResponse, String> {
  final AIRepository repository;

  SendInterviewMessageUseCase(this.repository);

  @override
  Future<Either<Failure, InterviewResponse>> execute(String params) async {
    return await repository.sendInterviewMessage(params);
  }
}
