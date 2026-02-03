import * as admin from "firebase-admin";

// Initialize Admin (Assumes GOOGLE_APPLICATION_CREDENTIALS is set or running in emulator)
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

const tasks = [
    // --- SQUATS ---
    {
        id: "squat_01",
        title: "Basic Squat",
        description: "Fundamental lower body exercise for quads and glutes.",
        advice: "Keep your chest up and weight on your heels.",
        category: "Legs",
        difficulty: 1,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/squat_01.mp4",
        bundlePath: "bundles/squat_01.zip",
        thumbnailPath: "thumbnails/squat_01.jpg",
        samplePosePath: "images/squat_01_ready.jpg"
    },
    {
        id: "squat_02",
        title: "Standard Squat (Alt)",
        description: "Alternative view for basic squat training.",
        advice: "Lower your hips until thighs are parallel to the floor.",
        category: "Legs",
        difficulty: 1,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/squat_02.mp4",
        bundlePath: "bundles/squat_01.zip",
        thumbnailPath: "thumbnails/squat_02.jpg",
        samplePosePath: "images/squat_01_ready.jpg"
    },
    {
        id: "wide_squat_01",
        title: "Wide Squat",
        description: "Sumo-style squat focusing on inner thighs.",
        advice: "Keep your feet wider than shoulder-width and toes pointed out.",
        category: "Legs",
        difficulty: 2,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/wide_squat_01.mp4",
        bundlePath: "bundles/wide_squat_01.zip",
        thumbnailPath: "thumbnails/wide_squat_01.jpg",
        samplePosePath: "images/wide_squat_01_ready.jpg"
    },
    {
        id: "jump_squat_01",
        title: "Jump Squat",
        description: "Explosive movement for power and cardio.",
        advice: "Land softly on the balls of your feet.",
        category: "Legs",
        difficulty: 3,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 90,
        videoPath: "videos/jump_squat_01.mp4",
        bundlePath: "bundles/jump_squat_01.zip",
        thumbnailPath: "thumbnails/jump_squat_01.jpg",
        samplePosePath: "images/squat_01_ready.jpg"
    },

    // --- PUSH-UPS ---
    {
        id: "pushup_01",
        title: "Standard Push-up",
        description: "Classic upper body builder for chest and triceps.",
        advice: "Maintain a straight line from head to heels.",
        category: "Upper Body",
        difficulty: 2,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/pushup_01.mp4",
        bundlePath: "bundles/pushup_01.zip",
        thumbnailPath: "thumbnails/pushup_01.jpg",
        samplePosePath: "images/pushup_01_ready.jpg"
    },
    {
        id: "knee_push_up_01",
        title: "Knee Push-up",
        description: "Modified push-up for beginners.",
        advice: "Keep your core tight and don't pike your hips.",
        category: "Upper Body",
        difficulty: 1,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/knee_push_up_01.mp4",
        bundlePath: "bundles/knee_pushup_01.zip",
        thumbnailPath: "thumbnails/knee_pushup_01.jpg",
        samplePosePath: "images/knee_pushup_01_ready.jpg"
    },
    {
        id: "diamond_push_up_01",
        title: "Diamond Push-up",
        description: "Triceps-focused push-up variation.",
        advice: "Form a diamond shape with your hands under your chest.",
        category: "Upper Body",
        difficulty: 3,
        reps: 8,
        sets: 3,
        isCountable: true,
        timeoutSec: 90,
        videoPath: "videos/diamond_push_up_01.mp4",
        bundlePath: "bundles/diamond_pushup_01.zip",
        thumbnailPath: "thumbnails/diamond_pushup_01.jpg",
        samplePosePath: "images/pushup_01_ready.jpg"
    },
    {
        id: "wave_push_up_01",
        title: "Wave Push-up",
        description: "Dynamic flow focusing on mobility and chest.",
        advice: "Peel your chest off the floor like a wave.",
        category: "Upper Body",
        difficulty: 2,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/wave_push_up_01.mp4",
        bundlePath: "bundles/wave_pushup_01.zip",
        thumbnailPath: "thumbnails/wave_pushup_01.jpg",
        samplePosePath: "images/pushup_01_ready.jpg"
    },

    // --- PLANKS ---
    {
        id: "plank_01",
        title: "Core Plank",
        description: "Static hold for core stability.",
        advice: "Engage your core and don't let your hips sag.",
        category: "Core",
        difficulty: 2,
        reps: 0,
        sets: 3,
        isCountable: false,
        timeoutSec: 60,
        durationSec: 45,
        videoPath: "videos/plank_01.mp4",
        bundlePath: "bundles/plank_01.zip",
        thumbnailPath: "thumbnails/plank_01.jpg",
        samplePosePath: "images/plank_01_ready.jpg"
    },
    {
        id: "elbow_plank_01",
        title: "Elbow Plank",
        description: "Classic plank on forearms.",
        advice: "Keep elbows directly under shoulders.",
        category: "Core",
        difficulty: 2,
        reps: 0,
        sets: 3,
        isCountable: false,
        timeoutSec: 60,
        durationSec: 45,
        videoPath: "videos/elbow_plank_01.mp4",
        bundlePath: "bundles/elbow_plank_01.zip",
        thumbnailPath: "thumbnails/elbow_plank_01.jpg",
        samplePosePath: "images/plank_01_ready.jpg"
    },
    {
        id: "side_plank_01",
        title: "Side Plank",
        description: "Focuses on obliques and lateral stability.",
        advice: "Lift your hips high and stack your feet.",
        category: "Core",
        difficulty: 2,
        reps: 0,
        sets: 2,
        isCountable: false,
        timeoutSec: 45,
        durationSec: 30,
        videoPath: "videos/side_plank_01.mp4",
        bundlePath: "bundles/side_plank_01.zip",
        thumbnailPath: "thumbnails/side_plank_01.jpg",
        samplePosePath: "images/side_plank_01_ready.jpg"
    },
    {
        id: "twist_plank_01",
        title: "Twist Plank",
        description: "Plank with hip rotation for obliques.",
        advice: "Rotate your hips side to side while keeping shoulders stable.",
        category: "Core",
        difficulty: 3,
        reps: 16,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/twist_plank_01.mp4",
        bundlePath: "bundles/twist_plank_01.zip",
        thumbnailPath: "thumbnails/twist_plank_01.jpg",
        samplePosePath: "images/plank_01_ready.jpg"
    },

    // --- LUNGES ---
    {
        id: "forward_lunge_01",
        title: "Forward Lunge",
        description: "Classic unilateral leg strength exercise.",
        advice: "Step forward and drop your back knee close to the ground.",
        category: "Legs",
        difficulty: 2,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/forward_lunge_01.mp4",
        bundlePath: "bundles/lunge_01.zip",
        thumbnailPath: "thumbnails/forward_lunge_01.jpg",
        samplePosePath: "images/lunge_01_ready.jpg"
    },
    {
        id: "back_lunge_01",
        title: "Back Lunge",
        description: "Great for balance and taxing the glutes.",
        advice: "Step backward and keep your front knee stable.",
        category: "Legs",
        difficulty: 2,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/back_lunge_01.mp4",
        bundlePath: "bundles/lunge_01.zip",
        thumbnailPath: "thumbnails/back_lunge_01.jpg",
        samplePosePath: "images/lunge_01_ready.jpg"
    },
    {
        id: "side_lunge_01",
        title: "Side Lunge",
        description: "Lateral movement for inner thighs and glutes.",
        advice: "Keep one leg straight and sit back into the lunging hip.",
        category: "Legs",
        difficulty: 2,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/side_lunge_01.mp4",
        bundlePath: "bundles/side_lunge_01.zip",
        thumbnailPath: "thumbnails/side_lunge_01.jpg",
        samplePosePath: "images/side_lunge_01_ready.jpg"
    },

    // --- FULL BODY / PLYOMETRIC ---
    {
        id: "mountain_climber_01",
        title: "Mountain Climber",
        description: "High-intensity core and cardio movement.",
        advice: "Run your knees toward your chest while staying in a plank.",
        category: "Full Body",
        difficulty: 3,
        reps: 20,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/mountain_climber_01.mp4",
        bundlePath: "bundles/mt_climber_01.zip",
        thumbnailPath: "thumbnails/mt_climber_01.jpg",
        samplePosePath: "images/plank_01_ready.jpg"
    }
];

async function seed() {
    console.log("🌱 Starting expanded seed...");
    const batch = db.batch();

    for (const task of tasks) {
        const ref = db.collection("exercises").doc(task.id);
        batch.set(ref, task);
    }

    await batch.commit();
    console.log(`✅ Seeded ${tasks.length} exercises successfully.`);
}

seed().catch(console.error);
