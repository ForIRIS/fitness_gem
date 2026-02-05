import * as admin from "firebase-admin";

// Initialize Admin (Assumes GOOGLE_APPLICATION_CREDENTIALS is set or running in emulator)
if (!admin.apps.length) {
    admin.initializeApp({
        projectId: "fitness-gem"
    });
}

const db = admin.firestore();

const tasks = [
    // === SQUATS ===
    {
        id: "squat_01",
        title: "Box Squat",
        description: "Beginner-friendly squat using a chair or box.",
        advice: "Place a chair or box behind you and practice sitting and standing up safely.",
        category: "squat",
        difficulty: 1,
        reps: 15,
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
        title: "Air Squat",
        description: "Basic air squat for building lower body strength.",
        advice: "Keep your back straight and engage your core muscles.",
        category: "squat",
        difficulty: 2,
        reps: 15,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/squat_02.mp4",
        bundlePath: "bundles/squat_02.zip",
        thumbnailPath: "thumbnails/squat_02.jpg",
        samplePosePath: "images/squat_02_ready.jpg"
    },
    {
        id: "squat_03",
        title: "Split Squat",
        description: "One-legged squat with balance maintenance.",
        advice: "Hold one leg and maintain balance. Lower back knee toward the floor.",
        category: "squat",
        difficulty: 3,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/squat_03.mp4",
        bundlePath: "bundles/squat_03.zip",
        thumbnailPath: "thumbnails/squat_03.jpg",
        samplePosePath: "images/squat_03_ready.jpg"
    },
    {
        id: "squat_04",
        title: "Jump Squat",
        description: "High-intensity jump squat for explosive power.",
        advice: "Land softly on your knees to absorb impact.",
        category: "squat",
        difficulty: 4,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/squat_04.mp4",
        bundlePath: "bundles/squat_04.zip",
        thumbnailPath: "thumbnails/squat_04.jpg",
        samplePosePath: "images/squat_04_ready.jpg"
    },

    // === PUSH-UPS ===
    {
        id: "push_01",
        title: "Wall Push-up",
        description: "Wall push-up for beginners.",
        advice: "Stand facing a wall with hands shoulder-width apart.",
        category: "push",
        difficulty: 1,
        reps: 15,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/push_01.mp4",
        bundlePath: "bundles/push_01.zip",
        thumbnailPath: "thumbnails/push_01.jpg",
        samplePosePath: "images/push_01_ready.jpg"
    },
    {
        id: "push_02",
        title: "Knee Push-up",
        description: "Modified push-up from your knees.",
        advice: "Keep your core tight and don't pike your hips.",
        category: "push",
        difficulty: 2,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/push_02.mp4",
        bundlePath: "bundles/push_02.zip",
        thumbnailPath: "thumbnails/push_02.jpg",
        samplePosePath: "images/push_02_ready.jpg"
    },
    {
        id: "push_03",
        title: "Standard Push-up",
        description: "Classic upper body builder for chest and triceps.",
        advice: "Maintain a straight line from head to heels.",
        category: "push",
        difficulty: 3,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/push_03.mp4",
        bundlePath: "bundles/push_03.zip",
        thumbnailPath: "thumbnails/push_03.jpg",
        samplePosePath: "images/push_03_ready.jpg"
    },
    {
        id: "push_04",
        title: "Diamond Push-up",
        description: "Triceps-focused push-up variation.",
        advice: "Form a diamond shape with your hands under your chest.",
        category: "push",
        difficulty: 4,
        reps: 8,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/push_04.mp4",
        bundlePath: "bundles/push_04.zip",
        thumbnailPath: "thumbnails/push_04.jpg",
        samplePosePath: "images/push_04_ready.jpg"
    },

    // === CORE / PLANKS ===
    {
        id: "core_01",
        title: "Elbow Plank",
        description: "Static hold for core stability on forearms.",
        advice: "Engage your core and don't let your hips sag.",
        category: "core",
        difficulty: 1,
        reps: 0,
        sets: 3,
        isCountable: false,
        timeoutSec: 30,
        durationSec: 30,
        videoPath: "videos/core_01.mp4",
        bundlePath: "bundles/core_01.zip",
        thumbnailPath: "thumbnails/core_01.jpg",
        samplePosePath: "images/core_01_ready.jpg"
    },
    {
        id: "core_02",
        title: "High Plank",
        description: "Plank on your hands for core stability.",
        advice: "Keep your body in a straight line with arms fully extended.",
        category: "core",
        difficulty: 2,
        reps: 0,
        sets: 3,
        isCountable: false,
        timeoutSec: 30,
        durationSec: 40,
        videoPath: "videos/core_02.mp4",
        bundlePath: "bundles/core_02.zip",
        thumbnailPath: "thumbnails/core_02.jpg",
        samplePosePath: "images/core_02_ready.jpg"
    },
    {
        id: "core_03",
        title: "Side Plank",
        description: "Focuses on obliques and lateral stability.",
        advice: "Lift your hips high and stack your feet.",
        category: "core",
        difficulty: 3,
        reps: 0,
        sets: 3,
        isCountable: false,
        timeoutSec: 30,
        durationSec: 30,
        videoPath: "videos/core_03.mp4",
        bundlePath: "bundles/core_03.zip",
        thumbnailPath: "thumbnails/core_03.jpg",
        samplePosePath: "images/core_03_ready.jpg"
    },
    {
        id: "core_04",
        title: "Plank with Leg Lift",
        description: "Plank with alternating leg lifts for core challenge.",
        advice: "Alternate lifting each leg while maintaining core stability.",
        category: "core",
        difficulty: 4,
        reps: 0,
        sets: 3,
        isCountable: false,
        timeoutSec: 30,
        durationSec: 45,
        videoPath: "videos/core_04.mp4",
        bundlePath: "bundles/core_04.zip",
        thumbnailPath: "thumbnails/core_04.jpg",
        samplePosePath: "images/core_04_ready.jpg"
    },

    // === LUNGES ===
    {
        id: "lunge_01",
        title: "Static Lunge",
        description: "Stationary lunge for leg strength.",
        advice: "Keep your front knee aligned over your ankle.",
        category: "lunge",
        difficulty: 1,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/lunge_01.mp4",
        bundlePath: "bundles/lunge_01.zip",
        thumbnailPath: "thumbnails/lunge_01.jpg",
        samplePosePath: "images/lunge_01_ready.jpg"
    },
    {
        id: "lunge_02",
        title: "Forward Lunge",
        description: "Step forward into a lunge position.",
        advice: "Step forward and drop your back knee close to the ground.",
        category: "lunge",
        difficulty: 2,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/lunge_02.mp4",
        bundlePath: "bundles/lunge_02.zip",
        thumbnailPath: "thumbnails/lunge_02.jpg",
        samplePosePath: "images/lunge_02_ready.jpg"
    },
    {
        id: "lunge_03",
        title: "Reverse Lunge",
        description: "Step backward into a lunge for glute focus.",
        advice: "Step backward and keep your front knee stable.",
        category: "lunge",
        difficulty: 3,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/lunge_03.mp4",
        bundlePath: "bundles/lunge_03.zip",
        thumbnailPath: "thumbnails/lunge_03.jpg",
        samplePosePath: "images/lunge_03_ready.jpg"
    },
    {
        id: "lunge_04",
        title: "Walking Lunge",
        description: "Lunge while walking for continuous challenge.",
        advice: "Maintain balance as you move forward.",
        category: "lunge",
        difficulty: 4,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: "videos/lunge_04.mp4",
        bundlePath: "bundles/lunge_04.zip",
        thumbnailPath: "thumbnails/lunge_04.jpg",
        samplePosePath: "images/lunge_04_ready.jpg"
    },
];

async function seed() {
    console.log("🌱 Starting exercise seed...");
    const batch = db.batch();

    for (const task of tasks) {
        const ref = db.collection("exercises").doc(task.id);
        batch.set(ref, task);
    }

    await batch.commit();
    console.log(`✅ Seeded ${tasks.length} exercises successfully.`);
}

seed().catch(error => {
    console.error("❌ SEQUENT_SEED_ERROR:", error);
    process.exit(1);
});
