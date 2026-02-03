import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * getWorkoutAssets - Firestore 기반 운동 자산 보안 URL 발급
 */
export const getWorkoutAssets = functions.https.onCall(async (request) => {
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
 * getAvailableWorkouts
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
 * notifyGuardian
 */
export const notifyGuardian = functions.https.onCall(async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be signed in.");
    }

    const callerUid = request.auth.uid;
    const db = admin.firestore();

    try {
        const callerDoc = await db.collection("users").doc(callerUid).get();
        if (!callerDoc.exists) {
            throw new functions.https.HttpsError("not-found", "User profile not found.");
        }

        const callerData = callerDoc.data() || {};
        const guardianEmail = callerData.guardianEmail;
        const callerName = callerData.nickname || "User";

        if (!guardianEmail) {
            throw new functions.https.HttpsError("failed-precondition", "No guardian linked.");
        }

        const guardianQuery = await db.collection("users")
            .where("email", "==", guardianEmail)
            .limit(1)
            .get();

        if (guardianQuery.empty) {
            throw new functions.https.HttpsError("not-found", "Guardian user not found.");
        }

        const guardianDoc = guardianQuery.docs[0];
        const guardianData = guardianDoc.data();
        const fcmToken = guardianData.fcmToken;

        if (!fcmToken) {
            throw new functions.https.HttpsError("failed-precondition", "Guardian has no notification token.");
        }

        const message = {
            token: fcmToken,
            notification: {
                title: "Emergency Alert! 🚨",
                body: `${callerName} may have fallen and needs help!`,
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
        throw new functions.https.HttpsError("internal", "Failed to notify guardian.");
    }
});

/**
 * helloWorld
 */
export const helloWorld = functions.https.onCall(async (request) => {
    return { message: "Health & Fitness Gem API is ready!" };
});

// ---------------------------------------------------------
// Guardian Connection System
// ---------------------------------------------------------

/**
 * sendGuardianRequest
 */
export const sendGuardianRequest = functions.https.onCall(async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be signed in.");
    }

    const { email } = request.data;
    if (!email) {
        throw new functions.https.HttpsError("invalid-argument", "Email is required.");
    }

    const db = admin.firestore();
    const requesterUid = request.auth.uid;

    try {
        const userQuery = await db.collection("users").where("email", "==", email).limit(1).get();
        if (userQuery.empty) {
            throw new functions.https.HttpsError("not-found", "User with this email not found.");
        }

        const targetUser = userQuery.docs[0];
        const targetUid = targetUser.id;

        if (requesterUid === targetUid) {
            throw new functions.https.HttpsError("invalid-argument", "You cannot be your own guardian.");
        }

        const existing = await db.collection("guardian_relations")
            .where("requester_uid", "==", requesterUid)
            .where("guardian_uid", "==", targetUid)
            .get();

        if (!existing.empty) {
            throw new functions.https.HttpsError("already-exists", "Request already sent to this user.");
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
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError("internal", "Failed to send request.");
    }
});

/**
 * respondToGuardianRequest
 */
export const respondToGuardianRequest = functions.https.onCall(async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be signed in.");
    }

    const { docId, accept } = request.data;
    const uid = request.auth.uid;
    const db = admin.firestore();

    try {
        const docRef = db.collection("guardian_relations").doc(docId);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new functions.https.HttpsError("not-found", "Request not found.");
        }

        const data = doc.data();
        if (data?.guardian_uid !== uid) {
            throw new functions.https.HttpsError("permission-denied", "Not authorized to respond.");
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
        throw new functions.https.HttpsError("internal", "Failed to respond.");
    }
});

/**
 * sendGuardianRequestNotification
 */
export const sendGuardianRequestNotification = functions.firestore
    .document('guardian_relations/{docId}')
    .onCreate(async (snapshot: any, context: any) => {
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
                docId: context.params.docId,
            }
        };

        await admin.messaging().send(message);
    });

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
