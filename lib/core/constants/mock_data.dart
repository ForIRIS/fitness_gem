import '../../data/models/workout_task_model.dart';

/// Shared mock data for workouts
const List<WorkoutTaskModel> mockWorkoutTasks = [
  // === Squat ===
  WorkoutTaskModel(
    id: 'squat_01',
    title: 'Box Squat',
    description:
        'A fundamental strength movement that utilizes a box to ensure consistent depth and improve posterior chain activation.',
    advice:
        'Sit back onto the box while maintaining a neutral spine. Drive through your mid-foot to return to a standing position, squeezing your glutes at the top.',
    thumbnail: 'assets/images/workouts/squat_01.png',
    readyPoseImageUrl: 'assets/images/workouts/squat_ready.png',
    reps: 15,
    sets: 3,
    timeoutSec: 60,
    category: 'squat',
    difficulty: 1,
  ),
  WorkoutTaskModel(
    id: 'squat_02',
    title: 'Wide Stance Squat',
    description:
        'A squat variation that emphasizes the adductors and glutes by widening the base of support. Increases hip mobility and lateral stability.',
    advice:
        'Keep your chest upright and knees tracking over your toes. Focus on pushing the floor away as you ascend to engage your inner thighs.',
    thumbnail: 'assets/images/workouts/squat_02.png',
    readyPoseImageUrl: 'assets/images/workouts/squat_ready.png',
    reps: 12,
    sets: 3,
    timeoutSec: 60,
    category: 'squat',
    difficulty: 2,
  ),
  WorkoutTaskModel(
    id: 'squat_03',
    title: 'Split Squat',
    description:
        'A unilateral lower body exercise that targets the quadriceps and glutes while challenging balance and core stability.',
    advice:
        'Maintain an upright torso and ensure your front knee stays aligned with your ankle. Control the descent to maximize time under tension.',
    thumbnail: 'assets/images/workouts/squat_03.png',
    readyPoseImageUrl: 'assets/images/workouts/squat_ready.png',
    reps: 8,
    sets: 3,
    timeoutSec: 60,
    category: 'squat',
    difficulty: 3,
  ),
  WorkoutTaskModel(
    id: 'squat_04',
    title: 'Jump Squat',
    description:
        'A high-intensity plyometric movement designed to develop explosive power in the lower body and enhance reactive strength.',
    advice:
        'Explode upwards and land softly by rolling from toe to heel, immediately absorbing the impact through your hips and knees.',
    thumbnail: 'assets/images/workouts/squat_04.png',
    readyPoseImageUrl: 'assets/images/workouts/squat_ready.png',
    reps: 8,
    sets: 3,
    timeoutSec: 60,
    category: 'squat',
    difficulty: 3,
  ),

  // === Push ===
  WorkoutTaskModel(
    id: 'push_01',
    title: 'Wall Push-up',
    description:
        'A beginner-friendly upper body exercise focusing on the pectorals, deltoids, and triceps with reduced gravitational load.',
    advice:
        'Keep your elbows at a 45-degree angle from your body and maintain a rigid core to protect your lumbar spine.',
    thumbnail: 'assets/images/workouts/push_01.png',
    readyPoseImageUrl: 'assets/images/workouts/pushup_ready.png',
    reps: 15,
    sets: 3,
    timeoutSec: 60,
    category: 'push',
    difficulty: 1,
  ),
  WorkoutTaskModel(
    id: 'push_02',
    title: 'Knee Push-up',
    description:
        'A progression toward the standard push-up that builds horizontal pressing strength while reducing the load on the lower body.',
    advice:
        'Maintain a straight line from your head to your knees. Engage your core and focus on pushing the floor away with your palms.',
    thumbnail: 'assets/images/workouts/push_02.png',
    readyPoseImageUrl: 'assets/images/workouts/pushup_ready.png',
    reps: 12,
    sets: 3,
    timeoutSec: 60,
    category: 'push',
    difficulty: 2,
  ),
  WorkoutTaskModel(
    id: 'push_03',
    title: 'Standard Push-up',
    description:
        'The gold standard for upper body pressing strength. Targets the chest, shoulders, and triceps while demanding significant core stability.',
    advice:
        'Engage your glutes and quads to keep your body perfectly linear. Lower yourself until your chest nearly touches the floor for full range of motion.',
    thumbnail: 'assets/images/workouts/push_03.png',
    readyPoseImageUrl: 'assets/images/workouts/pushup_ready.png',
    reps: 10,
    sets: 3,
    timeoutSec: 60,
    category: 'push',
    difficulty: 3,
  ),

  // === Core ===
  WorkoutTaskModel(
    id: 'core_01',
    title: 'Elbow Plank',
    description: 'Static hold for core stability on forearms.',
    advice: 'Engage your core and don\'t let your hips sag.',
    thumbnail: 'assets/images/workouts/core_01.png',
    readyPoseImageUrl: 'assets/images/workouts/plank_ready.png',
    reps: 0,
    sets: 3,
    timeoutSec: 60,
    durationSec: 30,
    isCountable: false,
    category: 'core',
    difficulty: 1,
  ),
  WorkoutTaskModel(
    id: 'core_02',
    title: 'High Plank',
    description: 'Plank on your hands for core stability.',
    advice: 'Keep your body in a straight line with arms fully extended.',
    thumbnail: 'assets/images/workouts/core_02.png',
    readyPoseImageUrl: 'assets/images/workouts/pushup_ready.png',
    reps: 0,
    sets: 3,
    timeoutSec: 60,
    durationSec: 40,
    isCountable: false,
    category: 'core',
    difficulty: 2,
  ),
  WorkoutTaskModel(
    id: 'core_03',
    title: 'Side Plank',
    description: 'Focuses on obliques and lateral stability.',
    advice: 'Lift your hips high and stack your feet.',
    thumbnail: 'assets/images/workouts/core_03.png',
    readyPoseImageUrl: 'assets/images/workouts/birddog_ready.png',
    reps: 0,
    sets: 3,
    timeoutSec: 60,
    durationSec: 30,
    isCountable: false,
    category: 'core',
    difficulty: 3,
  ),
  WorkoutTaskModel(
    id: 'core_04',
    title: 'Plank with Leg Lift',
    description: 'Plank with alternating leg lifts for core challenge.',
    advice: 'Alternate lifting each leg while maintaining core stability.',
    thumbnail: 'assets/images/workouts/core_04.png',
    readyPoseImageUrl: 'assets/images/workouts/glutebridge_ready.png',
    reps: 0,
    sets: 3,
    timeoutSec: 60,
    durationSec: 45,
    isCountable: false,
    category: 'core',
    difficulty: 4,
  ),

  // === Lunge ===
  WorkoutTaskModel(
    id: 'lunge_01',
    title: 'Static Lunge',
    description:
        'A unilateral movement that focuses on the quadriceps and glutes. Improves stability and prepares for dynamic lunging patterns.',
    advice:
        'Drop your back knee straight down toward the floor. Both knees should form approximately 90-degree angles at the bottom.',
    thumbnail: 'assets/images/workouts/lunge_01.png',
    readyPoseImageUrl: 'assets/images/workouts/lunge_ready.png',
    reps: 12,
    sets: 3,
    timeoutSec: 60,
    category: 'lunge',
    difficulty: 1,
  ),
  WorkoutTaskModel(
    id: 'lunge_02',
    title: 'Forward Lunge',
    description:
        'A dynamic exercise that challenges deceleration and balance. Enhances functional movement patterns used in daily activities.',
    advice:
        'Step forward decisively and maintain a vertical shin. Push back explosively to the starting position.',
    thumbnail: 'assets/images/workouts/lunge_02.png',
    readyPoseImageUrl: 'assets/images/workouts/lunge_ready.png',
    reps: 12,
    sets: 3,
    timeoutSec: 60,
    category: 'lunge',
    difficulty: 2,
  ),
  WorkoutTaskModel(
    id: 'lunge_03',
    title: 'Walking Lunge',
    description:
        'An advanced progression that combines lower body strength with continuous balance and coordination.',
    advice:
        'Keep your core engaged to prevent torso sway. Focus on a controlled, rhythmic pace as you move forward.',
    thumbnail: 'assets/images/workouts/lunge_03.png',
    readyPoseImageUrl: 'assets/images/workouts/lunge_ready.png',
    reps: 10,
    sets: 3,
    timeoutSec: 60,
    category: 'lunge',
    difficulty: 3,
  ),

  // === Explosive / Full Body ===
  WorkoutTaskModel(
    id: 'burpee_01',
    title: 'Classic Burpee',
    description:
        'A full-body metabolic exercise that combines strength, power, and cardiovascular endurance.',
    advice:
        'Maintain a tight core during the plank phase to protect your back. Explode into the jump and reach for the ceiling.',
    thumbnail: 'assets/images/workouts/squat_04.png',
    readyPoseImageUrl: 'assets/images/workouts/burpee_ready.png',
    reps: 10,
    sets: 3,
    timeoutSec: 90,
    category: 'fullbody',
    difficulty: 4,
  ),

  // === Shoulders ===
  WorkoutTaskModel(
    id: 'shoulder_01',
    title: 'Lateral Raise',
    description:
        'An isolation exercise specifically targeting the medial deltoids to build shoulder width and definition.',
    advice:
        'Lift with your elbows, not your hands. Keep a slight bend in your arms and control the eccentric (downward) phase.',
    thumbnail: 'assets/images/workouts/push_01.png',
    readyPoseImageUrl: 'assets/images/workouts/lateral_ready.png',
    reps: 12,
    sets: 3,
    timeoutSec: 60,
    category: 'shoulder',
    difficulty: 2,
  ),
];

/// Mock daily hot categories
const List<String> mockDailyHotCategories = [
  'Upper Body',
  'Build Strength',
  'Beginner',
  'Core Workout',
  'Lower Body',
  'HIIT Training',
];

/// Mock featured programs by category
const Map<String, Map<String, dynamic>> mockFeaturedPrograms = {
  'Build Strength': {
    'id': 'summer_shred_mock',
    'title': 'Summer Shred Challenge',
    'slogan': 'Get Set, Stay Ignite.',
    'description': 'High-intensity routine to burn calories and build muscle.',
    'imageUrl': 'assets/images/workouts/squat_04.png',
    'membersCount': '5.8k+',
    'rating': 5.0,
    'difficulty': 3,
    'duration': '18 Min',
    'task_ids': [
      'squat_04',
      'push_03',
      'lunge_03',
      'core_03',
      'squat_03',
      'push_02',
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
    'imageUrl': 'assets/images/workouts/push_01.png',
    'membersCount': '2.1k+',
    'rating': 4.8,
    'difficulty': 4,
    'duration': '20 Min',
    'task_ids': ['push_01', 'push_02', 'core_01', 'core_02'],
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
    'imageUrl': 'assets/images/workouts/squat_01.png',
    'membersCount': '12k+',
    'rating': 4.9,
    'difficulty': 1,
    'duration': '10 Min',
    'task_ids': ['squat_01', 'core_01'],
    'userAvatars': [
      'https://i.pravatar.cc/150?img=1',
      'https://i.pravatar.cc/150?img=2',
    ],
  },
};
