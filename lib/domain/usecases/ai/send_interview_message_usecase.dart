import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/ai_repository.dart';
import '../../entities/interview_response.dart';

class SendInterviewMessageParams {
  final String message;
  final File? image;
  SendInterviewMessageParams({required this.message, this.image});
}

class SendInterviewMessageUseCase
    implements UseCase<InterviewResponse, SendInterviewMessageParams> {
  final AIRepository repository;

  SendInterviewMessageUseCase(this.repository);

  @override
  Future<Either<Failure, InterviewResponse>> execute(
    SendInterviewMessageParams params,
  ) async {
    return await repository.sendInterviewMessage(
      params.message,
      image: params.image,
    );
  }
}
