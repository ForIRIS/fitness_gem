import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

admin.initializeApp();

// ---------------------------------------------------------
// Auth Triggers (Gen 1)
// ---------------------------------------------------------

/**
 * onUserAccountDeleted
 */
export const onUserAccountDeleted = functions.auth.user().onDelete(async (user: any) => {
    const uid = user.uid;
    const db = admin.firestore();
    const batch = db.batch();

    const sentRefs = await db.collection('guardian_relations').where('requester_uid', '==', uid).get();
    sentRefs.forEach(doc => batch.delete(doc.ref));

    const receivedRefs = await db.collection('guardian_relations').where('guardian_uid', '==', uid).get();
    receivedRefs.forEach(doc => batch.delete(doc.ref));

    await batch.commit();
});

// ---------------------------------------------------------
// HTTPS Callable Functions (Gen 2)
// ---------------------------------------------------------

/**
 * checkServerStatus
 */
export const checkServerStatus = onCall(async (request) => {
    return {
        status: "online",
        timestamp: Date.now(),
        message: "Health & Fitness Gem API is operational."
    };
});

/**
 * requestTaskInfo
 */
export const requestTaskInfo = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be signed in.");
    }

    const { task_ids } = request.data;
    if (!task_ids || !Array.isArray(task_ids)) {
        throw new HttpsError("invalid-argument", "Missing task_ids array.");
    }

    const db = admin.firestore();
    const bucket = admin.storage().bucket();
    const expiration = Date.now() + 60 * 60 * 1000; // 1 hour

    const results = await Promise.all(task_ids.map(async (id: string) => {
        try {
            const doc = await db.collection("exercises").doc(id).get();
            if (!doc.exists) {
                return { id, error: "not_found" };
            }

            const data = doc.data() || {};
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
                bundleUrl: await sign(data.bundlePath),
                videoUrl: await sign(data.videoPath),
                thumbnailUrl: await sign(data.thumbnailPath),
                readyPoseImageUrl: await sign(data.samplePosePath),
                audioUrl: null,
                coremlUrl: null,
                onnxUrl: null
            };
        } catch (error) {
            console.error(`Process error for ${id}:`, error);
            return { id, error: "processing_failed" };
        }
    }));

    return { task_urls: results };
});

/**
 * getDailyHotCategories
 */
export const getDailyHotCategories = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be signed in.");
    }

    return {
        categories: [
            'Upper Body',
            'Build Strength',
            'Beginner',
            'Core Workout',
            'Lower Body',
            'HIIT Training',
        ]
    };
});

/**
 * getFeaturedProgram
 */
export const getFeaturedProgram = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be signed in.");
    }

    return {
        id: 'summer_shred_mock',
        title: 'Summer Shred Challenge',
        description: 'High-intensity routine to burn calories and build muscle.',
        imageUrl: 'assets/images/workouts/squat_04.png',
        slogan: 'Get Set, Stay Ignite.',
        membersCount: '5.8k+',
        rating: 5.0,
        difficulty: 3,
        task_ids: [
            'squat_04',
            'push_03',
            'lunge_03',
            'core_03',
            'squat_03',
            'push_02',
        ],
        userAvatars: [
            'https://i.pravatar.cc/150?img=12',
            'https://i.pravatar.cc/150?img=24',
            'https://i.pravatar.cc/150?img=33',
        ]
    };
});



/**
 * getAvailableWorkouts
 */
export const getAvailableWorkouts = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be signed in.");
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
        throw new HttpsError("internal", "Failed to fetch workouts.");
    }
});

/**
 * notifyGuardian
 */
export const notifyGuardian = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be signed in.");
    }

    const callerUid = request.auth.uid;
    const db = admin.firestore();

    try {
        const callerDoc = await db.collection("users").doc(callerUid).get();
        if (!callerDoc.exists) {
            throw new HttpsError("not-found", "User profile not found.");
        }

        const callerData = callerDoc.data() || {};
        const guardianEmail = callerData.guardianEmail;
        const callerName = callerData.nickname || "User";
        const location = request.data.location; // Optional location string/url

        if (!guardianEmail) {
            throw new HttpsError("failed-precondition", "No guardian linked.");
        }

        const guardianQuery = await db.collection("users")
            .where("email", "==", guardianEmail)
            .limit(1)
            .get();

        if (guardianQuery.empty) {
            throw new HttpsError("not-found", "Guardian user not found.");
        }

        const guardianDoc = guardianQuery.docs[0];
        const guardianData = guardianDoc.data();
        const fcmToken = guardianData.fcmToken;

        if (!fcmToken) {
            throw new HttpsError("failed-precondition", "Guardian has no notification token.");
        }

        const message = {
            token: fcmToken,
            notification: {
                title: "Emergency Alert! 🚨",
                body: `${callerName} may have fallen and needs help!${location ? `\nLocation: ${location}` : ''}`,
            },
            data: {
                type: "fall_alert",
                userId: callerUid,
                timestamp: Date.now().toString(),
            },
            android: {
                priority: "high" as const,
                notification: {
                    channelId: "emergency_channel",
                    priority: "max" as const,
                    defaultSound: true,
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                    }
                }
            }
        };

        const response = await admin.messaging().send(message);
        return { success: true, messageId: response };

    } catch (error) {
        console.error("Emergency notification failed:", error);
        throw new HttpsError("internal", "Failed to notify guardian.");
    }
});

// ---------------------------------------------------------
// Guardian Connection System
// ---------------------------------------------------------

/**
 * sendGuardianRequest
 */
export const sendGuardianRequest = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be signed in.");
    }

    const { email } = request.data;
    if (!email) {
        throw new HttpsError("invalid-argument", "Email is required.");
    }

    const db = admin.firestore();
    const requesterUid = request.auth.uid;

    try {
        const userQuery = await db.collection("users").where("email", "==", email).limit(1).get();
        if (userQuery.empty) {
            throw new HttpsError("not-found", "User with this email not found.");
        }

        const targetUser = userQuery.docs[0];
        const targetUid = targetUser.id;

        if (requesterUid === targetUid) {
            throw new HttpsError("invalid-argument", "You cannot be your own guardian.");
        }

        const existing = await db.collection("guardian_relations")
            .where("requester_uid", "==", requesterUid)
            .where("guardian_uid", "==", targetUid)
            .get();

        if (!existing.empty) {
            throw new HttpsError("already-exists", "Request already sent to this user.");
        }

        await db.collection("guardian_relations").add({
            requester_uid: requesterUid,
            guardian_uid: targetUid,
            requester_email: request.auth.token.email || "Unknown",
            guardian_email: email,
            status: "pending",
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true };

    } catch (error) {
        console.error("sendGuardianRequest failed:", error);
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", "Failed to send request.");
    }
});

/**
 * respondToGuardianRequest
 */
export const respondToGuardianRequest = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be signed in.");
    }

    const { docId, accept } = request.data;
    const uid = request.auth.uid;
    const db = admin.firestore();

    try {
        const docRef = db.collection("guardian_relations").doc(docId);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new HttpsError("not-found", "Request not found.");
        }

        const data = doc.data();
        if (data?.guardian_uid !== uid) {
            throw new HttpsError("permission-denied", "Not authorized to respond.");
        }

        if (accept) {
            await docRef.update({
                status: "accepted",
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
            });
        } else {
            await docRef.delete();
        }

        return { success: true };

    } catch (error) {
        console.error("respondToGuardianRequest failed:", error);
        throw new HttpsError("internal", "Failed to respond.");
    }
});

/**
 * sendGuardianRequestNotification
 */
export const sendGuardianRequestNotification = onDocumentCreated(
    "guardian_relations/{docId}",
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) {
            return;
        }
        const data = snapshot.data();
        const guardianUid = data.guardian_uid;
        const requesterEmail = data.requester_email;

        const db = admin.firestore();

        const guardianDoc = await db.collection("users").doc(guardianUid).get();
        if (!guardianDoc.exists) return;

        const fcmToken = guardianDoc.data()?.fcmToken;
        if (!fcmToken) return;

        const message = {
            token: fcmToken,
            notification: {
                title: "Guardian Request 🛡️",
                body: `${requesterEmail} wants to set you as their Safety Guardian. Check the app to respond.`,
            },
            data: {
                type: "guardian_request",
                docId: event.params.docId,
            }
        };

        await admin.messaging().send(message);
    }
);
