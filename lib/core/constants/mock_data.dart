import '../../data/models/workout_task_model.dart';

/// Shared mock data for workouts
const List<WorkoutTaskModel> mockWorkoutTasks = [
  // === Squat ===
  WorkoutTaskModel(
    id: 'squat_air',
    title: 'Air Squat',
    description:
        'A fundamental bodyweight movement that builds lower body strength and mobility.',
    advice:
        'Keep your chest up, back straight, and lower your hips until your thighs are parallel to the floor.',
    thumbnail: 'assets/thumbnails/air_squat.png',
    readyPoseImageUrl: 'assets/images/workouts/air_squat_ready.png',
    exampleVideoUrl: 'assets/videos/air_squat.mp4',
    reps: 15,
    sets: 3,
    timeoutSec: 60,
    category: 'squat',
    difficulty: 1,
  ),
  WorkoutTaskModel(
    id: 'squat_wide',
    title: 'Wide Squat',
    description:
        'A squat variation with a wider stance to target the inner thighs and glutes.',
    advice:
        'Step wider than shoulder-width, point toes slightly out, and push knees out as you descend.',
    thumbnail: 'assets/thumbnails/wide_squat.png',
    readyPoseImageUrl: 'assets/images/workouts/wide_squat_ready.png',
    exampleVideoUrl: 'assets/videos/wide_squat.mp4',
    reps: 12,
    sets: 3,
    timeoutSec: 60,
    category: 'squat',
    difficulty: 2,
  ),
  WorkoutTaskModel(
    id: 'squat_jump',
    title: 'Jump Squat',
    description:
        'A plyometric exercise that adds an explosive jump to the standard squat.',
    advice:
        'Explode up from the bottom of the squat, landing softly on the balls of your feet.',
    thumbnail: 'assets/thumbnails/jump_squat.png', // Fallback
    readyPoseImageUrl:
        'assets/images/workouts/jump_squat_ready.png', // Fallback
    exampleVideoUrl: 'assets/videos/jump_squat.mp4',
    reps: 10,
    sets: 3,
    timeoutSec: 60,
    category: 'squat',
    difficulty: 3,
  ),

  // === Lunge ===
  WorkoutTaskModel(
    id: 'lunge_standard',
    title: 'Standard Lunge',
    description:
        'A unilateral leg exercise that improves balance, coordination, and strength.',
    advice:
        'Step forward, lowering your hips until both knees are bent at a 90-degree angle.',
    thumbnail: 'assets/images/workouts/lunge_ready.png',
    readyPoseImageUrl: 'assets/images/workouts/lunge_ready.png',
    exampleVideoUrl: 'assets/videos/lunge.mp4',
    reps: 12,
    sets: 3,
    timeoutSec: 60,
    category: 'lunge',
    difficulty: 2,
  ),
  WorkoutTaskModel(
    id: 'lunge_side',
    title: 'Side Lunge',
    description:
        'A lateral movement that targets the inner and outer thighs, glutes, and hips.',
    advice:
        'Step out to the side, keeping the other leg straight, and push your hips back.',
    thumbnail: 'assets/thumbnails/side_lunge.png', // Fallback
    readyPoseImageUrl:
        'assets/images/workouts/side_lunge_ready.png', // Fallback
    exampleVideoUrl: 'assets/videos/side_lunge.mp4',
    reps: 10,
    sets: 3,
    timeoutSec: 60,
    category: 'lunge',
    difficulty: 2,
  ),

  // === Push ===
  WorkoutTaskModel(
    id: 'pushup_standard',
    title: 'Standard Push-up',
    description:
        'A classic upper body exercise for chest, shoulders, and triceps strength.',
    advice:
        'Keep your body in a straight line, lower your chest to the floor, and push back up.',
    thumbnail: 'assets/thumbnails/push_03.png',
    readyPoseImageUrl: 'assets/images/workouts/pushup_ready.png',
    exampleVideoUrl: 'assets/videos/push_up.mp4',
    reps: 10,
    sets: 3,
    timeoutSec: 60,
    category: 'push',
    difficulty: 3,
  ),
  WorkoutTaskModel(
    id: 'pushup_knee',
    title: 'Knee Push-up',
    description:
        'A modified push-up performed on the knees, great for building upper body strength.',
    advice:
        'Rest on your knees, maintain a straight line from head to knees, and perform the push-up.',
    thumbnail: 'assets/thumbnails/push_03.png', // Same ready pose
    readyPoseImageUrl: 'assets/images/workouts/pushup_ready.png',
    exampleVideoUrl: 'assets/videos/knee_pushup.mp4',
    reps: 12,
    sets: 3,
    timeoutSec: 60,
    category: 'push',
    difficulty: 1,
  ),
  WorkoutTaskModel(
    id: 'pushup_diamond',
    title: 'Diamond Push-up',
    description:
        'A triceps-focused push-up variation with hands close together forming a diamond shape.',
    advice:
        'Place hands close together under your chest, elbows tucked in, and lower yourself.',
    thumbnail: 'assets/thumbnails/push_04.png', // Fallback
    readyPoseImageUrl: 'assets/images/workouts/push_04.png', // Fallback
    exampleVideoUrl: 'assets/videos/diamond_pushup.mp4',
    reps: 8,
    sets: 3,
    timeoutSec: 60,
    category: 'push',
    difficulty: 4,
  ),

  // === Core ===
  WorkoutTaskModel(
    id: 'plank_standard',
    title: 'Standard Plank',
    description:
        'An isometric core exercise that strengthens the entire body, especially the abs.',
    advice:
        'Hold a straight body position, supporting yourself on your forearms (or hands) and toes.',
    thumbnail:
        'assets/thumbnails/plank.png', // Using elbow plank image for generic plank
    readyPoseImageUrl: 'assets/thumbnails/plank.png',
    exampleVideoUrl: 'assets/videos/plank.mp4',
    reps: 0,
    sets: 3,
    timeoutSec: 60,
    durationSec: 45,
    isCountable: false,
    category: 'core',
    difficulty: 2,
  ),
  WorkoutTaskModel(
    id: 'plank_elbow',
    title: 'Elbow Plank',
    description:
        'A plank variation performed on the elbows, emphasizing core stability and endurance.',
    advice:
        'Rest on your forearms, keep your elbows under your shoulders, and hold a straight line.',
    thumbnail: 'assets/thumbnails/elbow_plank.png',
    readyPoseImageUrl: 'assets/images/workouts/elbow_plank_ready.jpeg',
    exampleVideoUrl: 'assets/videos/elbow_plank.mp4',
    reps: 0,
    sets: 3,
    timeoutSec: 60,
    durationSec: 30,
    isCountable: false,
    category: 'core',
    difficulty: 2,
  ),
  WorkoutTaskModel(
    id: 'plank_side',
    title: 'Side Plank',
    description:
        'Targets the obliques and improves lateral core stability and balance.',
    advice:
        'Lie on your side, lift your hips to form a straight line, and hold.',
    thumbnail: 'assets/thumbnails/side_plank.png',
    readyPoseImageUrl: 'assets/images/workouts/side_plank.jpg', // Fallback
    exampleVideoUrl: 'assets/videos/side_plank.mp4',
    reps: 0,
    sets: 3,
    timeoutSec: 60,
    durationSec: 30,
    isCountable: false,
    category: 'core',
    difficulty: 3,
  ),
  WorkoutTaskModel(
    id: 'core_birddog',
    title: 'Bird Dog',
    description:
        'Improves balance and stability by simultaneously extending opposite arm and leg.',
    advice:
        'On hands and knees, extend opposite arm and leg, hold briefly, then switch.',
    thumbnail: 'assets/thumbnails/birddog.png',
    readyPoseImageUrl: 'assets/images/workouts/birddog_ready.jpg',
    exampleVideoUrl: 'assets/videos/bird_dog.mp4',
    reps: 12,
    sets: 3,
    timeoutSec: 60,
    category: 'core',
    difficulty: 2,
  ),
  WorkoutTaskModel(
    id: 'core_glutebridge',
    title: 'Glute Bridge',
    description: 'Targets the glutes and hamstrings while opening up the hips.',
    advice:
        'Lie on your back, knees bent, lift your hips until your body forms a straight line.',
    thumbnail: 'assets/thumbnails/glute_bridge.png',
    readyPoseImageUrl: 'assets/images/workouts/glute_bridge_ready.png',
    exampleVideoUrl: 'assets/videos/glute_bridge.mp4',
    reps: 15,
    sets: 3,
    timeoutSec: 60,
    category: 'core',
    difficulty: 1,
  ),
];

/// Mock daily hot categories
const List<String> mockDailyHotCategories = [
  'Build Strength',
  'Upper Body',
  'Beginner',
];

/// Mock featured programs by category
const Map<String, Map<String, dynamic>> mockFeaturedPrograms = {
  'Build Strength': {
    'id': 'summer_shred_mock',
    'title': 'Summer Shred Challenge',
    'slogan': 'Get Set, Stay Ignite.',
    'description': 'High-intensity routine to burn calories and build muscle.',
    'imageUrl': 'assets/thumbnails/air_squat.png',
    'membersCount': '5.8k+',
    'rating': 5.0,
    'difficulty': 3,
    'duration': '18 Min',
    'task_ids': [
      'squat_air',
      'pushup_standard',
      'lunge_standard',
      'plank_standard',
      'squat_wide',
      'pushup_knee',
    ],
    'userAvatars': [
      'https://i.pravatar.cc/150?img=11',
      'https://i.pravatar.cc/150?img=12',
      'https://i.pravatar.cc/150?img=33',
    ],
  },
  'Upper Body': {
    'id': 'upper_blast_mock',
    'title': 'Boulder Shoulders 30',
    'slogan': 'Sculpt Your Upper Body.',
    'description': 'Focus on deltoids and chest with this intense circuit.',
    'imageUrl': 'assets/thumbnails/push_02.png',
    'membersCount': '2.1k+',
    'rating': 4.8,
    'difficulty': 4,
    'duration': '20 Min',
    'task_ids': [
      'pushup_standard',
      'pushup_diamond',
      'plank_elbow',
      'plank_side',
    ],
    'userAvatars': [
      'https://i.pravatar.cc/150?img=59',
      'https://i.pravatar.cc/150?img=60',
    ],
  },
  'Beginner': {
    'id': 'starter_mock',
    'title': 'Zero to Hero: Week 1',
    'slogan': 'Start Your Journey Today.',
    'description': 'Low impact movements designed for absolute beginners.',
    'imageUrl': 'assets/thumbnails/glute_bridge.png',
    'membersCount': '12k+',
    'rating': 4.9,
    'difficulty': 1,
    'duration': '10 Min',
    'task_ids': ['squat_air', 'core_glutebridge'],
    'userAvatars': [
      'https://i.pravatar.cc/150?img=1',
      'https://i.pravatar.cc/150?img=2',
    ],
  },
};
