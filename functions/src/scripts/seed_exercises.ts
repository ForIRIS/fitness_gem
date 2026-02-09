import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import * as dotenv from "dotenv";

// Load environment variables from .env file
dotenv.config();

const projectId = process.env.FITNESS_PROJECT_ID || "fitness-gem";
const databaseId = process.env.FITNESS_DATABASE_ID || "(default)";

// Initialize Admin (Assumes GOOGLE_APPLICATION_CREDENTIALS is set or running in emulator)
if (!admin.apps.length) {
    admin.initializeApp({
        projectId: projectId
    });
}

const db = getFirestore(databaseId);

const tasks = [
    // === SQUAT ===
    {
        id: 'squat_air',
        title: 'Air Squat',
        description: 'A fundamental bodyweight movement that builds lower body strength and mobility.',
        advice: 'Keep your chest up, back straight, and lower your hips until your thighs are parallel to the floor.',
        category: 'squat',
        difficulty: 1,
        reps: 15,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/air_squat.mp4',
        bundlePath: 'bundles/squat_air.zip',
        thumbnailPath: 'thumbnails/air_squat.png',
        samplePosePath: 'images/air_squat_ready.png'
    },
    {
        id: 'squat_wide',
        title: 'Wide Squat',
        description: 'A squat variation with a wider stance to target the inner thighs and glutes.',
        advice: 'Step wider than shoulder-width, point toes slightly out, and push knees out as you descend.',
        category: 'squat',
        difficulty: 2,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/wide_squat.mp4',
        bundlePath: 'bundles/squat_wide.zip',
        thumbnailPath: 'thumbnails/wide_squat.png',
        samplePosePath: 'images/wide_squat_ready.png'
    },
    {
        id: 'squat_jump',
        title: 'Jump Squat',
        description: 'A plyometric exercise that adds an explosive jump to the standard squat.',
        advice: 'Explode up from the bottom of the squat, landing softly on the balls of your feet.',
        category: 'squat',
        difficulty: 3,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/jump_squat.mp4',
        bundlePath: 'bundles/squat_jump.zip',
        thumbnailPath: 'thumbnails/jump_squat.png',
        samplePosePath: 'images/jump_squat_ready.png'
    },

    // === LUNGE ===
    {
        id: 'lunge_standard',
        title: 'Standard Lunge',
        description: 'A unilateral leg exercise that improves balance, coordination, and strength.',
        advice: 'Step forward, lowering your hips until both knees are bent at a 90-degree angle.',
        category: 'lunge',
        difficulty: 2,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/lunge.mp4',
        bundlePath: 'bundles/lunge_standard.zip',
        thumbnailPath: 'images/lunge_ready.png', // Corrected: Using image from workouts folder as thumbnail
        samplePosePath: 'images/lunge_ready.png'
    },
    {
        id: 'lunge_side',
        title: 'Side Lunge',
        description: 'A lateral movement that targets the inner and outer thighs, glutes, and hips.',
        advice: 'Step out to the side, keeping the other leg straight, and push your hips back.',
        category: 'lunge',
        difficulty: 2,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/side_lunge.mp4',
        bundlePath: 'bundles/lunge_side.zip',
        thumbnailPath: 'thumbnails/side_lunge.png',
        samplePosePath: 'images/side_lunge_ready.png'
    },

    // === PUSH ===
    {
        id: 'pushup_standard',
        title: 'Standard Push-up',
        description: 'A classic upper body exercise for chest, shoulders, and triceps strength.',
        advice: 'Keep your body in a straight line, lower your chest to the floor, and push back up.',
        category: 'push',
        difficulty: 3,
        reps: 10,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/push_up.mp4',
        bundlePath: 'bundles/pushup_standard.zip',
        thumbnailPath: 'thumbnails/push_03.png',
        samplePosePath: 'images/pushup_ready.png'
    },
    {
        id: 'pushup_knee',
        title: 'Knee Push-up',
        description: 'A modified push-up performed on the knees, great for building upper body strength.',
        advice: 'Rest on your knees, maintain a straight line from head to knees, and perform the push-up.',
        category: 'push',
        difficulty: 1,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/knee_pushup.mp4',
        bundlePath: 'bundles/pushup_knee.zip',
        thumbnailPath: 'thumbnails/push_03.png',
        samplePosePath: 'images/pushup_ready.png'
    },
    {
        id: 'pushup_diamond',
        title: 'Diamond Push-up',
        description: 'A triceps-focused push-up variation with hands close together forming a diamond shape.',
        advice: 'Place hands close together under your chest, elbows tucked in, and lower yourself.',
        category: 'push',
        difficulty: 4,
        reps: 8,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/diamond_pushup.mp4',
        bundlePath: 'bundles/pushup_diamond.zip',
        thumbnailPath: 'thumbnails/push_04.png',
        samplePosePath: 'images/push_04.png'
    },

    // === CORE ===
    {
        id: 'plank_standard',
        title: 'Standard Plank',
        description: 'An isometric core exercise that strengthens the entire body, especially the abs.',
        advice: 'Hold a straight body position, supporting yourself on your forearms (or hands) and toes.',
        category: 'core',
        difficulty: 2,
        reps: 0,
        sets: 3,
        isCountable: false,
        timeoutSec: 60,
        durationSec: 45,
        videoPath: 'videos/plank.mp4',
        bundlePath: 'bundles/plank_standard.zip',
        thumbnailPath: 'thumbnails/plank.png',
        samplePosePath: 'thumbnails/plank.png'
    },
    {
        id: 'plank_elbow',
        title: 'Elbow Plank',
        description: 'A plank variation performed on the elbows, emphasizing core stability and endurance.',
        advice: 'Rest on your forearms, keep your elbows under your shoulders, and hold a straight line.',
        category: 'core',
        difficulty: 2,
        reps: 0,
        sets: 3,
        isCountable: false,
        timeoutSec: 60,
        durationSec: 30,
        videoPath: 'videos/elbow_plank.mp4',
        bundlePath: 'bundles/plank_elbow.zip',
        thumbnailPath: 'thumbnails/elbow_plank.png',
        samplePosePath: 'images/elbow_plank_ready.jpeg'
    },
    {
        id: 'plank_side',
        title: 'Side Plank',
        description: 'Targets the obliques and improves lateral core stability and balance.',
        advice: 'Lie on your side, lift your hips to form a straight line, and hold.',
        category: 'core',
        difficulty: 3,
        reps: 0,
        sets: 3,
        isCountable: false,
        timeoutSec: 60,
        durationSec: 30,
        videoPath: 'videos/side_plank.mp4',
        bundlePath: 'bundles/plank_side.zip',
        thumbnailPath: 'thumbnails/side_plank.png', // Corrected: Using file from thumbnails folder
        samplePosePath: 'images/side_plank.jpg' // Corrected extension
    },
    {
        id: 'core_birddog',
        title: 'Bird Dog',
        description: 'Improves balance and stability by simultaneously extending opposite arm and leg.',
        advice: 'On hands and knees, extend opposite arm and leg, hold briefly, then switch.',
        category: 'core',
        difficulty: 2,
        reps: 12,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/bird_dog.mp4',
        bundlePath: 'bundles/core_birddog.zip',
        thumbnailPath: 'thumbnails/birddog.png', // Corrected: Using file from thumbnails folder
        samplePosePath: 'images/birddog_ready.jpg' // Corrected extension
    },
    {
        id: 'core_glutebridge',
        title: 'Glute Bridge',
        description: 'Targets the glutes and hamstrings while opening up the hips.',
        advice: 'Lie on your back, knees bent, lift your hips until your body forms a straight line.',
        category: 'core',
        difficulty: 1,
        reps: 15,
        sets: 3,
        isCountable: true,
        timeoutSec: 60,
        videoPath: 'videos/glute_bridge.mp4',
        bundlePath: 'bundles/core_glutebridge.zip',
        thumbnailPath: 'thumbnails/glute_bridge.png',
        samplePosePath: 'images/glute_bridge_ready.png'
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
