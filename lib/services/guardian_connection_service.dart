import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GuardianConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a guardian request to the specified email
  Future<void> sendGuardianRequest(String email) async {
    try {
      final callable = _functions.httpsCallable('sendGuardianRequest');
      await callable.call({'email': email});
    } catch (e) {
      debugPrint('Error sending guardian request: $e');
      rethrow;
    }
  }

  /// Respond to a pending guardian request
  Future<void> respondToRequest(String docId, bool accept) async {
    try {
      final callable = _functions.httpsCallable('respondToGuardianRequest');
      await callable.call({'docId': docId, 'accept': accept});
    } catch (e) {
      debugPrint('Error responding to request: $e');
      rethrow;
    }
  }

  /// Get the active confirmed guardian relation (if any)
  Future<QueryDocumentSnapshot?> getActiveGuardianRelation() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Check where user is requester
    final sentQuery = await _firestore
        .collection('guardian_relations')
        .where('requester_uid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'accepted')
        .limit(1)
        .get();

    if (sentQuery.docs.isNotEmpty) return sentQuery.docs.first;

    // Check where user is guardian (though this usually means THEY are the guardian)
    // The requirement is usually for the *Protected User* to verify connection.
    // So 'requester_uid' == me is correct for "My Guardian".

    return null;
  }

  /// Listen to the status of my guardian connection
  Stream<QuerySnapshot> listenToMyGuardianStatus() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('guardian_relations')
        .where('requester_uid', isEqualTo: user.uid)
        .snapshots();
  }

  /// Listen to incoming requests (Where I am the target guardian)
  Stream<QuerySnapshot> listenToIncomingRequests() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('guardian_relations')
        .where('guardian_uid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Revoke a connection or Cancel a request
  Future<void> revokeConnection(String docId) async {
    try {
      await _firestore.collection('guardian_relations').doc(docId).delete();
    } catch (e) {
      debugPrint('Error revoking connection: $e');
      rethrow;
    }
  }
}
