import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../models/workout_task.dart';

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
          .map((doc) => WorkoutTask.fromMap(doc.data()))
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
          .map((doc) => WorkoutTask.fromMap(doc.data()))
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
          .map((doc) => WorkoutTask.fromMap(doc.data()))
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

  /// 더미 데이터 업로드 (개발용)
  Future<void> uploadDummyData() async {
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('workouts');

    for (final task in _dummyWorkoutTasks) {
      final docRef = collection.doc(task.id);
      batch.set(docRef, task.toMap());
    }

    await batch.commit();
    debugPrint('Uploaded dummy data to Firestore');
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

  // ============ 더미 데이터 (16종 운동) ============

  static final List<WorkoutTask> _dummyWorkoutTasks = [
    // === 하체 (Squat) ===
    WorkoutTask(
      id: 'squat_01',
      title: 'Box Squat',
      description: 'Beginner-friendly squat using a chair or box',
      advice:
          'Place a chair or box behind you and practice sitting and standing up safely. Ensure your knees do not extend significantly past your toes.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 15,
      sets: 3,
      timeoutSec: 60,
      category: 'squat',
      difficulty: 1,
    ),
    WorkoutTask(
      id: 'squat_02',
      title: 'Air Squat',
      description: 'Basic air squat',
      advice:
          'Keep your back straight and engage your core muscles. Maintain a neutral spine and focus on proper form to prevent injury.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 15,
      sets: 3,
      timeoutSec: 60,
      category: 'squat',
      difficulty: 2,
    ),
    WorkoutTask(
      id: 'squat_03',
      title: 'Split Squat',
      description: 'One-legged squat with balance maintenance',
      advice:
          'Hold one leg and maintain balance. Adjust the back knee to touch the floor as if you were about to sit down.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 12,
      sets: 3,
      timeoutSec: 60,
      category: 'squat',
      difficulty: 3,
    ),
    WorkoutTask(
      id: 'squat_04',
      title: 'Jump Squat',
      description: 'High-intensity jump squat',
      advice:
          'Land softly on your knees to absorb impact. Land quietly by lightly jumping.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
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
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 15,
      sets: 3,
      timeoutSec: 60,
      category: 'push',
      difficulty: 1,
    ),
    WorkoutTask(
      id: 'push_02',
      title: 'Knee Push-up',
      description: 'Knee push-up',
      advice:
          'Stand with your knees bent and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 12,
      sets: 3,
      timeoutSec: 60,
      category: 'push',
      difficulty: 2,
    ),
    WorkoutTask(
      id: 'push_03',
      title: 'Standard Push-up',
      description: 'Standard push-up',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      category: 'push',
      difficulty: 3,
    ),
    WorkoutTask(
      id: 'push_04',
      title: 'Diamond Push-up',
      description: 'Diamond push-up',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 8,
      sets: 3,
      timeoutSec: 60,
      category: 'push',
      difficulty: 4,
    ),

    // === 코어 (Core) ===
    WorkoutTask(
      id: 'core_01',
      title: 'Elbow Plank',
      description: 'Elbow plank',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 1, // 플랭크는 시간 기반
      sets: 3,
      timeoutSec: 30,
      category: 'core',
      difficulty: 1,
    ),
    WorkoutTask(
      id: 'core_02',
      title: 'High Plank',
      description: 'High plank',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 1,
      sets: 3,
      timeoutSec: 30,
      category: 'core',
      difficulty: 2,
    ),
    WorkoutTask(
      id: 'core_03',
      title: 'Side Plank',
      description: 'Side plank',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 1,
      sets: 3,
      timeoutSec: 30,
      category: 'core',
      difficulty: 3,
    ),
    WorkoutTask(
      id: 'core_04',
      title: 'Plank with Leg Lift',
      description: 'Plank with leg lift',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 1,
      sets: 3,
      timeoutSec: 30,
      category: 'core',
      difficulty: 4,
    ),

    // === 런지 (Lunge) ===
    WorkoutTask(
      id: 'lunge_01',
      title: 'Static Lunge',
      description: 'Static lunge',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 12,
      sets: 3,
      timeoutSec: 60,
      category: 'lunge',
      difficulty: 1,
    ),
    WorkoutTask(
      id: 'lunge_02',
      title: 'Forward Lunge',
      description: 'Forward lunge',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 12,
      sets: 3,
      timeoutSec: 60,
      category: 'lunge',
      difficulty: 2,
    ),
    WorkoutTask(
      id: 'lunge_03',
      title: 'Reverse Lunge',
      description: 'Reverse lunge',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      category: 'lunge',
      difficulty: 3,
    ),
    WorkoutTask(
      id: 'lunge_04',
      title: 'Walking Lunge',
      description: 'Walking lunge',
      advice:
          'Stand with your feet shoulder-width apart and hands shoulder-width apart. Lower your body until your chest touches the floor. Push back up to the starting position.',
      thumbnail: '',
      readyPoseImageUrl: '',
      exampleVideoUrl: '',
      configureUrl: '',
      guideAudioUrl: '',
      reps: 10,
      sets: 3,
      timeoutSec: 60,
      category: 'lunge',
      difficulty: 4,
    ),
  ];
}
