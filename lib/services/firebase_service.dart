import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../firebase_options.dart';
import '../domain/entities/workout_task.dart';
import '../domain/entities/workout_curriculum.dart';
import '../data/models/workout_task_model.dart';

/// FirebaseService - Firebase 초기화 및 운동 라이브러리 관리
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;
  bool _isOffline = false; // Auth 실패 시 오프라인 모드로 동작

  /// Firebase 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 익명 로그인
    await _signInAnonymously();

    _initialized = true;
  }

  /// 익명 로그인
  Future<void> _signInAnonymously() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        debugPrint('Signed in anonymously: ${auth.currentUser?.uid}');
      }
    } catch (e) {
      debugPrint('Anonymous sign in failed: $e');
      _isOffline = true; // 실패 시 오프라인 모드 활성화
    }
  }

  /// 현재 사용자 ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ============ 운동 라이브러리 (더미 데이터) ============

  /// 모든 운동 목록 조회
  Future<List<WorkoutTask>> fetchWorkoutAllList() async {
    if (_isOffline) return _dummyWorkoutTasks;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .get();

      if (snapshot.docs.isEmpty) {
        // 데이터가 없으면 더미 데이터 업로드 (개발 편의성)
        await uploadDummyData();
        return _dummyWorkoutTasks;
      }

      return snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error fetching workouts: $e');
      // 에러 발생 시 더미 데이터 반환 (오프라인 등)
      return _dummyWorkoutTasks;
    }
  }

  /// 카테고리별 운동 검색
  Future<List<WorkoutTask>> searchWorkoutParts(String category) async {
    if (_isOffline) {
      return _dummyWorkoutTasks
          .where(
            (task) => task.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .where('category', isEqualTo: category.toLowerCase())
          .get();

      if (snapshot.docs.isEmpty) {
        // Firestore에 없으면 더미에서 검색
        return _dummyWorkoutTasks
            .where(
              (task) => task.category.toLowerCase() == category.toLowerCase(),
            )
            .toList();
      }

      return snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error searching workouts: $e');
      return _dummyWorkoutTasks
          .where(
            (task) => task.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    }
  }

  /// 특정 운동 조회
  Future<List<WorkoutTask>> fetchWorkoutTask(
    List<String> workoutTaskIds,
  ) async {
    if (workoutTaskIds.isEmpty) return [];
    if (_isOffline) {
      return _dummyWorkoutTasks
          .where((task) => workoutTaskIds.contains(task.id))
          .toList();
    }

    try {
      // whereIn은 최대 10개까지만 가능하므로 10개씩 끊어서 요청 (여기서는 간단히 처리)
      if (workoutTaskIds.length > 10) {
        // 단순화를 위해 10개 이상은 개별 쿼리 병렬 처리 or 그냥 fetchAll 후 필터링
        // MVP: Fetch All and Filter (데이터가 적으므로)
        final all = await fetchWorkoutAllList();
        return all.where((t) => workoutTaskIds.contains(t.id)).toList();
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .where('id', whereIn: workoutTaskIds)
          .get();

      final fetched = snapshot.docs
          .map((doc) => WorkoutTaskModel.fromMap(doc.data()).toEntity())
          .toList();

      // 만약 Firestore에서 못 찾은 게 있으면 더미에서 찾기 (Mixed scenarios)
      if (fetched.length < workoutTaskIds.length) {
        final foundIds = fetched.map((e) => e.id).toSet();
        final missingIds = workoutTaskIds.where((id) => !foundIds.contains(id));

        final dummyFound = _dummyWorkoutTasks
            .where((task) => missingIds.contains(task.id))
            .toList();

        fetched.addAll(dummyFound);
      }

      return fetched;
    } catch (e) {
      debugPrint('Error fetching workout tasks: $e');
      return _dummyWorkoutTasks
          .where((task) => workoutTaskIds.contains(task.id))
          .toList();
    }
  }

  /// Cloud Function을 통해 운동 미디어 URL(Signed URL) 요청
  /// Returns updated tasks with URLs populated
  Future<List<WorkoutTask>> requestTaskUrls(List<WorkoutTask> tasks) async {
    if (tasks.isEmpty) return tasks;

    try {
      final taskIds = tasks.map((t) => t.id).toList();
      final result = await FirebaseFunctions.instance
          .httpsCallable('requestTaskInfo')
          .call({'task_ids': taskIds});

      final List<dynamic> taskUrls = result.data['task_urls'];
      final updatedTasks = <WorkoutTask>[];

      for (var task in tasks) {
        final taskData = taskUrls.firstWhere(
          (data) => data['id'] == task.id,
          orElse: () => null,
        );

        if (taskData != null) {
          // Create new task with updated URLs
          updatedTasks.add(
            WorkoutTask(
              id: task.id,
              title: task.title,
              description: task.description,
              advice: task.advice,
              category: task.category,
              difficulty: task.difficulty,
              reps: task.reps,
              sets: task.sets,
              timeoutSec: task.timeoutSec,
              durationSec: task.durationSec,
              isCountable: task.isCountable,
              thumbnail: taskData['thumbnail'] ?? task.thumbnail,
              readyPoseImageUrl:
                  taskData['readyPoseImageUrl'] ?? task.readyPoseImageUrl,
              exampleVideoUrl: taskData['videoUrl'] ?? task.exampleVideoUrl,
              configureUrl: taskData['configureUrl'] ?? task.configureUrl,
              guideAudioUrl: taskData['audioUrl'] ?? task.guideAudioUrl,
              coremlUrl: taskData['coremlUrl'] ?? task.coremlUrl,
              onnxUrl: taskData['onnxUrl'] ?? task.onnxUrl,
              adjustedReps: task.adjustedReps,
              adjustedSets: task.adjustedSets,
            ),
          );
        } else {
          updatedTasks.add(task);
        }
      }

      return updatedTasks;
    } catch (e) {
      debugPrint('Error calling requestTaskInfo: $e');
      return tasks; // Return original tasks on error
    }
  }

  /// 더미 데이터 업로드 (개발용)
  Future<void> uploadDummyData() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final task in _dummyWorkoutTasks) {
        final docRef = FirebaseFirestore.instance
            .collection('workouts')
            .doc(task.id);
        batch.set(docRef, WorkoutTaskModel.fromEntity(task).toMap());
      }
      await batch.commit();
      debugPrint('Dummy data uploaded successfully');
    } catch (e) {
      debugPrint('Error uploading dummy data: $e');
    }
  }

  /// Gemini에 전달할 운동 목록 텍스트
  Future<String> getWorkoutListForGemini(String category) async {
    final tasks = await searchWorkoutParts(category);
    final buffer = StringBuffer();
    buffer.writeln('Available workouts for category "$category":');
    for (final task in tasks) {
      buffer.writeln('- ID: ${task.id}');
      buffer.writeln('  Title: ${task.title}');
      buffer.writeln('  Description: ${task.description}');
      buffer.writeln('  Difficulty: ${task.difficultyDisplayName}');
      buffer.writeln('  Default Reps: ${task.reps}, Sets: ${task.sets}');
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// 일일 인기 카테고리 조회
  Future<List<String>> fetchDailyHotCategories() async {
    if (_isOffline) {
      // 오프라인 모드일 경우 목업 데이터 반환
      return mockDailyHotCategories;
    }

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getDailyHotCategories')
          .call();

      final List<dynamic> categories = result.data['categories'];
      return categories.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error fetching daily hot categories: $e');
      // 에러 발생 시 목업 데이터 반환
      return mockDailyHotCategories;
    }
  }

  /// 추천 프로그램 조회
  Future<WorkoutCurriculum?> fetchFeaturedProgram() async {
    try {
      Map<String, dynamic> data;

      if (_isOffline) {
        data = mockFeaturedProgram;
      } else {
        try {
          final result = await FirebaseFunctions.instance
              .httpsCallable('getFeaturedProgram')
              .call();
          data = Map<String, dynamic>.from(result.data);
        } catch (e) {
          debugPrint('Error fetching featured program: $e');
          data = mockFeaturedProgram;
        }
      }

      final taskIds = (data['task_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();

      final tasks = await fetchWorkoutTask(taskIds);

      final orderedTasks = <WorkoutTask>[];
      for (final id in taskIds) {
        if (tasks.any((t) => t.id == id)) {
          orderedTasks.add(tasks.firstWhere((t) => t.id == id));
        }
      }

      return WorkoutCurriculum(
        id: data['id'] ?? 'featured',
        title: data['title'] ?? 'Featured Program',
        description: data['description'] ?? '',
        workoutTasks: orderedTasks,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating featured program: $e');
      return null;
    }
  }

  // ============ 더미 데이터 (16종 운동) ============

  static const Map<String, dynamic> mockFeaturedProgram = {
    'id': 'summer_shred_mock',
    'title': 'Summer Shred Challenge (Mock)',
    'description': 'High-intensity routine to burn calories and build muscle.',
    'task_ids': [
      'squat_04',
      'push_03',
      'lunge_03',
      'core_03',
      'squat_03',
      'push_02',
    ],
    'imageUrl': 'assets/images/workouts/squat_04.png',
  };

  static const List<String> mockDailyHotCategories = [
    'Upper Body',
    'Build Strength',
    'Beginner',
    'Core Workout',
    'Lower Body',
    'HIIT Training',
  ];

  static final List<WorkoutTask> _dummyWorkoutTasks = [
    // === 하체 (Squat) ===
    WorkoutTask(
      id: 'squat_01',
      title: 'Box Squat',
      description: 'Beginner-friendly squat using a chair or box',
      advice:
          'Place a chair or box behind you and practice sitting and standing up safely. Ensure your knees do not extend significantly past your toes.',
      thumbnail: 'assets/images/workouts/squat_01.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 15,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'squat',
      difficulty: 1,
    ),
    WorkoutTask(
      id: 'squat_02',
      title: 'Air Squat',
      description: 'Basic air squat',
      advice:
          'Keep your back straight and engage your core muscles. Maintain a neutral spine and focus on proper form to prevent injury.',
      thumbnail: 'assets/images/workouts/squat_02.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 15,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'squat',
      difficulty: 2,
    ),
    WorkoutTask(
      id: 'squat_03',
      title: 'Split Squat',
      description: 'One-legged squat with balance maintenance',
      advice:
          'Hold one leg and maintain balance. Adjust the back knee to touch the floor as if you were about to sit down.',
      thumbnail: 'assets/images/workouts/squat_03.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 12,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'squat',
      difficulty: 3,
    ),
    WorkoutTask(
      id: 'squat_04',
      title: 'Jump Squat',
      description: 'High-intensity jump squat',
      advice:
          'Land softly on your knees to absorb impact. Land quietly by lightly jumping.',
      thumbnail: 'assets/images/workouts/squat_04.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'squat',
      difficulty: 4,
    ),

    // === 상체 (Push) ===
    WorkoutTask(
      id: 'push_01',
      title: 'Wall Push-up',
      description: 'Wall push-up',
      advice:
          'Stand facing a wall with your hands shoulder-width apart. Lean forward until your chest touches the wall. Push back up to the starting position.',
      thumbnail: 'assets/images/workouts/push_01.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 15,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'push',
      difficulty: 1,
    ),
    WorkoutTask(
      id: 'push_02',
      title: 'Knee Push-up',
      description: 'Knee push-up',
      advice:
          'Stand with your knees bent and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: 'assets/images/workouts/push_02.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 12,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'push',
      difficulty: 2,
    ),
    WorkoutTask(
      id: 'push_03',
      title: 'Standard Push-up',
      description: 'Standard push-up',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: 'assets/images/workouts/push_03.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'push',
      difficulty: 3,
    ),
    WorkoutTask(
      id: 'push_04',
      title: 'Diamond Push-up',
      description: 'Diamond push-up',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: 'assets/images/workouts/push_04.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 8,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'push',
      difficulty: 4,
    ),

    // === 코어 (Core) ===
    WorkoutTask(
      id: 'core_01',
      title: 'Elbow Plank',
      description: 'Elbow plank',
      advice:
          'Maintain a straight line from head to heels. Engage your core and avoid letting your hips sag. Hold the position for the specified duration.',
      thumbnail: 'assets/images/workouts/core_01.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 0, // Duration-based exercise
      sets: 3,
      timeoutSec: 30,
      durationSec: 30,
      isCountable: false,
      category: 'core',
      difficulty: 1,
    ),
    WorkoutTask(
      id: 'core_02',
      title: 'High Plank',
      description: 'High plank',
      advice:
          'Keep your body in a straight line with arms fully extended. Engage your core and maintain proper alignment. Hold for the specified duration.',
      thumbnail: 'assets/images/workouts/core_02.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 0, // Duration-based exercise
      sets: 3,
      timeoutSec: 30,
      durationSec: 40,
      isCountable: false,
      category: 'core',
      difficulty: 2,
    ),
    WorkoutTask(
      id: 'core_03',
      title: 'Side Plank',
      description: 'Side plank',
      advice:
          'Balance on one forearm with your body in a straight line. Stack your feet or stagger them for stability. Hold the position for the specified duration.',
      thumbnail: 'assets/images/workouts/core_03.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 0, // Duration-based exercise
      sets: 3,
      timeoutSec: 30,
      durationSec: 30,
      isCountable: false,
      category: 'core',
      difficulty: 3,
    ),
    WorkoutTask(
      id: 'core_04',
      title: 'Plank with Leg Lift',
      description: 'Plank with leg lift',
      advice:
          'Start in a high plank position. Alternate lifting each leg while maintaining core stability. Hold the position for the specified duration.',
      thumbnail: 'assets/images/workouts/core_04.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 0, // Duration-based exercise
      sets: 3,
      timeoutSec: 30,
      durationSec: 45,
      isCountable: false,
      category: 'core',
      difficulty: 4,
    ),

    // === 런지 (Lunge) ===
    WorkoutTask(
      id: 'lunge_01',
      title: 'Static Lunge',
      description: 'Static lunge',
      advice:
          'Keep your front knee aligned over your ankle. Lower your back knee toward the floor while maintaining an upright torso. Push through your front heel to return to starting position.',
      thumbnail: 'assets/images/workouts/lunge_01.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 12,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'lunge',
      difficulty: 1,
    ),
    WorkoutTask(
      id: 'lunge_02',
      title: 'Forward Lunge',
      description: 'Forward lunge',
      advice:
          'Step forward with one leg and lower your hips until both knees are bent at 90 degrees. Push back to the starting position. Alternate legs with each rep.',
      thumbnail: 'assets/images/workouts/lunge_02.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 12,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'lunge',
      difficulty: 2,
    ),
    WorkoutTask(
      id: 'lunge_03',
      title: 'Reverse Lunge',
      description: 'Reverse lunge',
      advice:
          'Step backward with one leg and lower your hips until both knees are bent at 90 degrees. Push through your front heel to return to starting position. Alternate legs.',
      thumbnail: 'assets/images/workouts/lunge_03.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'lunge',
      difficulty: 3,
    ),
    WorkoutTask(
      id: 'lunge_04',
      title: 'Walking Lunge',
      description: 'Walking lunge',
      advice:
          'Step forward into a lunge and continue walking forward, alternating legs with each step. Maintain balance and control throughout the movement.',
      thumbnail: 'assets/images/workouts/lunge_04.png',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      isCountable: true,
      category: 'lunge',
      difficulty: 4,
    ),
  ];
}
