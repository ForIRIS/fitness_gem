import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/interview_response.dart';
import '../../entities/user_profile.dart';

class ChatWithImageParams {
  final String userMessage;
  final File imageFile;
  final UserProfile? profile;

  ChatWithImageParams({
    required this.userMessage,
    required this.imageFile,
    this.profile,
  });
}

class ChatWithImageUseCase
    implements UseCase<InterviewResponse, ChatWithImageParams> {
  ChatWithImageUseCase();

  @override
  Future<Either<Failure, InterviewResponse>> execute(
    ChatWithImageParams params,
  ) async {
    // Feature migrating placeholder
    return Right(
      InterviewResponse(message: 'Feature migrating...', isComplete: false),
    );
  }
}
