import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/workout_task.dart';

/// FirebaseService - Firebase 초기화 및 운동 라이브러리 관리
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;

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
    }
  }

  /// 현재 사용자 ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ============ 운동 라이브러리 (더미 데이터) ============

  /// 모든 운동 목록 조회
  Future<List<WorkoutTask>> fetchWorkoutAllList() async {
    // TODO: Firestore 연동 시 실제 데이터로 교체
    return _dummyWorkoutTasks;
  }

  /// 카테고리별 운동 검색
  Future<List<WorkoutTask>> searchWorkoutParts(String category) async {
    // TODO: Firestore 연동 시 실제 쿼리로 교체
    return _dummyWorkoutTasks
        .where((task) => task.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// 특정 운동 조회
  Future<List<WorkoutTask>> fetchWorkoutTask(
    List<String> workoutTaskIds,
  ) async {
    // TODO: Firestore 연동 시 실제 쿼리로 교체
    return _dummyWorkoutTasks
        .where((task) => workoutTaskIds.contains(task.id))
        .toList();
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
      description: '의자나 박스를 이용한 초보자용 스쿼트',
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
      koreanAdvice:
          '의자나 박스를 뒤에 두고 안전하게 앉았다 일어나는 연습을 하세요. 무릎이 발끝보다 많이 나가지 않도록 주의합니다.',
    ),
    WorkoutTask(
      id: 'squat_02',
      title: 'Air Squat',
      description: '맨몸 스쿼트의 기본형',
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
      koreanAdvice:
          '허리를 곧게 펴고 시선은 정면을 유지하세요. 발뒤꿈치에 무게중심을 두고 앉아야 무릎 부상을 방지할 수 있습니다.',
    ),
    WorkoutTask(
      id: 'squat_03',
      title: 'Split Squat',
      description: '한 발을 뒤로 빼고 하는 스쿼트',
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
      koreanAdvice:
          '한쪽 다리에 체중을 싣고 균형을 유지하는 것이 중요합니다. 내려갈 때 뒷다리의 무릎이 바닥에 닿을 듯 말 듯 하게 조절하세요.',
    ),
    WorkoutTask(
      id: 'squat_04',
      title: 'Jump Squat',
      description: '점프를 포함한 고강도 스쿼트',
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
      koreanAdvice:
          '착지 시 무릎을 부드럽게 굽혀 충격을 흡수하세요. 쿵 소리가 나지 않도록 가볍게 뛰는 것이 포인트입니다.',
    ),

    // === 상체 (Push) ===
    WorkoutTask(
      id: 'push_01',
      title: 'Wall Push-up',
      description: '벽을 이용한 초보자용 푸시업',
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
      koreanAdvice: '벽에서 발을 멀리 둘수록 운동 강도가 높아집니다. 손목이 꺾이지 않도록 손바닥 전체로 벽을 미세요.',
    ),
    WorkoutTask(
      id: 'push_02',
      title: 'Knee Push-up',
      description: '무릎을 대고 하는 푸시업',
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
      koreanAdvice:
          '무릎을 대고 하더라도 어깨부터 무릎까지 일직선을 유지하세요. 엉덩이가 솟거나 처지면 허리에 무리가 갈 수 있습니다.',
    ),
    WorkoutTask(
      id: 'push_03',
      title: 'Standard Push-up',
      description: '일반 푸시업',
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
      koreanAdvice: '팔꿈치가 몸통에서 45도 정도 벌어지게 하세요. 너무 넓게 벌리면 어깨 부상의 위험이 있습니다.',
    ),
    WorkoutTask(
      id: 'push_04',
      title: 'Diamond Push-up',
      description: '손을 모아서 하는 고강도 푸시업',
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
      koreanAdvice:
          '손을 다이아몬드 모양으로 모아 삼두근 자극을 극대화합니다. 중심을 잃지 않도록 천천히 동작을 수행하세요.',
    ),

    // === 코어 (Core) ===
    WorkoutTask(
      id: 'core_01',
      title: 'Elbow Plank',
      description: '팔꿈치 플랭크 (초보자용)',
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
      koreanAdvice:
          '엉덩이가 들리거나 허리가 꺾이지 않도록 복부에 힘을 꽉 주세요. 시선은 손 사이 바닥을 바라보면 목이 편안합니다.',
    ),
    WorkoutTask(
      id: 'core_02',
      title: 'High Plank',
      description: '팔을 뻗은 플랭크',
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
      koreanAdvice:
          '손목과 어깨가 수직이 되도록 위치시키세요. 어깨가 귀랑 멀어지도록 날개뼈를 아래로 당기는 느낌을 유지하세요.',
    ),
    WorkoutTask(
      id: 'core_03',
      title: 'Side Plank',
      description: '옆으로 하는 플랭크',
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
      koreanAdvice:
          '몸이 일직선이 되도록 옆구리를 들어 올리세요. 지지하는 팔의 어깨가 눌리지 않도록 바닥을 강하게 밀어냅니다.',
    ),
    WorkoutTask(
      id: 'core_04',
      title: 'Plank with Leg Lift',
      description: '다리를 들어올리는 플랭크',
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
      koreanAdvice:
          '다리를 들어 올릴 때 골반이 틀어지지 않도록 주의하세요. 코어의 힘으로 몸통을 고정하는 것이 핵심입니다.',
    ),

    // === 런지 (Lunge) ===
    WorkoutTask(
      id: 'lunge_01',
      title: 'Static Lunge',
      description: '제자리 런지',
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
      koreanAdvice: '제자리에서 앉았다 일어나는 동작입니다. 앞쪽 무릎이 안쪽으로 쏠리지 않도록 발끝 방향과 일치시키세요.',
    ),
    WorkoutTask(
      id: 'lunge_02',
      title: 'Forward Lunge',
      description: '앞으로 나가는 런지',
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
      koreanAdvice:
          '앞으로 나갈 때 상체가 앞으로 쏠리지 않도록 복부에 힘을 주세요. 돌아올 때는 앞발 뒤꿈치로 바닥을 밀어 제자리로 옵니다.',
    ),
    WorkoutTask(
      id: 'lunge_03',
      title: 'Reverse Lunge',
      description: '뒤로 빠지는 런지',
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
      koreanAdvice: '뒤로 발을 뻗을 때 균형을 잃지 않도록 주의하세요. 엉덩이 근육의 자극을 느끼며 동작을 수행합니다.',
    ),
    WorkoutTask(
      id: 'lunge_04',
      title: 'Walking Lunge',
      description: '걸으면서 하는 런지',
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
      koreanAdvice:
          '걸으면서 런지를 할 때는 보폭을 일정하게 유지하세요. 무릎에 통증이 느껴지면 보폭을 줄이거나 멈춰주세요.',
    ),
  ];
}
