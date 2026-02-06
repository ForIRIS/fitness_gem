import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:fitness_gem/data/datasources/remote/gemini_datasource.dart';
import 'package:fitness_gem/data/models/user_profile_model.dart';
import 'package:fitness_gem/data/models/workout_task_model.dart';
import 'package:fitness_gem/core/wrappers/gemini_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

// Mock GeminiWrapper (Interface)
class MockGeminiWrapper extends Mock implements GeminiWrapper {
  @override
  Future<GenerateContentResponse> generateContent(Iterable<Content>? prompt) {
    return super.noSuchMethod(
          Invocation.method(#generateContent, [prompt]),
          returnValue: Future.value(GenerateContentResponse([], null)),
          returnValueForMissingStub: Future.value(
            GenerateContentResponse([], null),
          ),
        )
        as Future<GenerateContentResponse>;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeminiDataSourceImpl dataSource;
  late MockGeminiWrapper mockWrapper;

  setUp(() async {
    mockWrapper = MockGeminiWrapper();
    dataSource = GeminiDataSourceImpl(wrapper: mockWrapper);
  });

  final tProfile = UserProfileModel(
    id: '1',
    nickname: 'Test User',
    age: 25,
    gender: 'Male',
    height: 180,
    weight: 75,
    fitnessLevel: 'Intermediate',
    targetExercise: 'Squat',
    healthConditions: 'None',
    goal: 'Strength',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final tTask = WorkoutTaskModel(
    id: 'squat_01',
    title: 'Squat',
    description: 'Basic Squat',
    advice: 'Keep back straight',
    reps: 10,
    sets: 3,
    timeoutSec: 60,
    category: 'squat',
    difficulty: 1,
  );

  test(
    'should return WorkoutCurriculumModel when API call is successful',
    () async {
      // Arrange
      final jsonResponse = {
        'id': 'ai_123',
        'title': 'AI Workout',
        'description': 'Test Plan',
        'workoutTaskList': [
          {
            'id': 'squat_01',
            'reps': 15, // Changed
            'sets': 4,
            'timeoutSec': 45,
          },
        ],
      };

      final responseText = jsonEncode(jsonResponse);

      when(mockWrapper.generateContent(any)).thenAnswer(
        (_) async => GenerateContentResponse([
          Candidate(
            Content('model', [TextPart(responseText)]),
            null,
            null,
            null,
            null,
          ),
        ], null),
      );

      // Act
      final result = await dataSource.generateCurriculum(
        profile: tProfile,
        category: 'Strength',
        availableTasks: [tTask],
      );

      // Assert
      expect(result.id, 'ai_123');
      expect(result.workoutTasks.length, 1);
      expect(result.workoutTasks.first.reps, 15);
      expect(result.workoutTasks.first.sets, 4);
      verify(mockWrapper.generateContent(any)).called(1);
    },
  );
}
