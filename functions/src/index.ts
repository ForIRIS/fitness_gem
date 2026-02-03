import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * getWorkoutAssets - Firestore 기반 운동 자산 보안 URL 발급
 * 
 * 1. 클라이언트가 보내준 taskIds를 사용하여 Firestore 'exercises' 컬렉션 조회
 * 2. 각 운동 문서에 정의된 실제 Storage 경로를 가져옴
 * 3. 해당 경로에 대해 1시간 동안 유효한 Signed URL 발급
 */
export const getWorkoutAssets = functions.https.onCall(async (request) => {
    // 1. 인증 확인
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be signed in.");
    }

    const { task_ids } = request.data;
    if (!task_ids || !Array.isArray(task_ids)) {
        throw new functions.https.HttpsError("invalid-argument", "Missing task_ids array.");
    }

    const db = admin.firestore();
    const bucket = admin.storage().bucket();
    const expiration = Date.now() + 60 * 60 * 1000; // 1 hour

    const results = await Promise.all(task_ids.map(async (id) => {
        try {
            // Firestore에서 운동 정보 조회
            const doc = await db.collection("exercises").doc(id).get();
            if (!doc.exists) {
                console.warn(`Exercise ${id} not found in Firestore.`);
                return { id, error: "not_found" };
            }

            const data = doc.data() || {};

            // Signed URL 생성 유틸리티
            const sign = async (path: string | undefined) => {
                if (!path) return null;
                try {
                    const [url] = await bucket.file(path).getSignedUrl({ action: 'read', expires: expiration });
                    return url;
                } catch (e) {
                    console.error(`Signing error for ${path}:`, e);
                    return null;
                }
            };

            return {
                id,
                // Firestore에 정의된 경로를 그대로 사용 (보안 우수)
                bundleUrl: await sign(data.bundlePath),
                videoUrl: await sign(data.videoPath),
                thumbnailUrl: await sign(data.thumbnailPath),
                samplePoseUrl: await sign(data.samplePosePath),
            };
        } catch (error) {
            console.error(`Process error for ${id}:`, error);
            return { id, error: "processing_failed" };
        }
    }));

    return { assets: results };
});

/**
 * getAvailableWorkouts - 모든 운동의 기본 정보(Meta)를 반환
 * 커리큘럼 생성을 위해 클라이언트가 호출합니다.
 */
export const getAvailableWorkouts = functions.https.onCall(async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be signed in.");
    }

    try {
        const snapshot = await admin.firestore().collection("exercises").get();
        const workouts = snapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                title: data.title,
                description: data.description,
                category: data.category,
                difficulty: data.difficulty,
                reps: data.reps,
                sets: data.sets,
                isCountable: data.isCountable,
                durationSec: data.durationSec,
            };
        });
        return { workouts };
    } catch (error) {
        throw new functions.https.HttpsError("internal", "Failed to fetch workouts.");
    }
});

/**
 * helloWorld - 연결 테스트용
 */
export const helloWorld = functions.https.onCall(async (request) => {
    return { message: "Health & Fitness Gem API is ready!" };
});
