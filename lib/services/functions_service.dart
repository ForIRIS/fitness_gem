import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// FunctionsService - Manage Firebase Cloud Functions calls
class FunctionsService {
  static final FunctionsService _instance = FunctionsService._internal();
  factory FunctionsService() => _instance;
  FunctionsService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Check server status (for testing)
  Future<Map<String, dynamic>?> checkServerStatus() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'checkServerStatus',
      );
      final results = await callable.call();

      debugPrint('Server Status: ${results.data}');
      return results.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error: ${e.code}');
      debugPrint('Cloud Function Details: ${e.details}');
      debugPrint('Cloud Function Message: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error calling checkServerStatus: $e');
      return null;
    }
  }

  /// Request workout assets safely (Bundle Zip, Video, etc.)
  Future<List<Map<String, dynamic>>> getWorkoutAssets(
    List<String> taskIds,
  ) async {
    if (taskIds.isEmpty) return [];

    try {
      // Ensure authenticated (Anonymous)
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      final results = await _functions.httpsCallable('requestTaskInfo').call({
        'task_ids': taskIds,
      });

      final data = results.data as Map<dynamic, dynamic>;
      final assets = data['task_urls'] as List<dynamic>?;

      if (assets == null) return [];
      return assets.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Error calling getWorkoutAssets: $e');
      return [];
    }
  }

  /// Gemini workout analysis request (Proxy)
  Future<Map<String, dynamic>?> analyzeWorkoutInterSet({
    required String rgbUri,
    required String controlNetUri,
    Map<String, dynamic>? context,
    String? prompt,
    String? systemInstruction,
  }) async {
    try {
      final results = await _functions
          .httpsCallable('analyzeWorkoutInterSet')
          .call({
            'rgb_uri': rgbUri,
            'control_net_uri': controlNetUri,
            'context': context,
            'prompt': prompt,
            'system_instruction': systemInstruction,
          });

      return results.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error calling analyzeWorkoutInterSet: $e');
      return null;
    }
  }

  /// Fall detection AI verification request
  Future<Map<String, dynamic>?> verifyFallDetection(String videoUri) async {
    try {
      final results = await _functions
          .httpsCallable('verifyFallDetection')
          .call({'video_uri': videoUri});

      return results.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error calling verifyFallDetection: $e');
      return null;
    }
  }

  /// Emulator settings (for development)
  void useEmulator(String host, int port) {
    try {
      _functions.useFunctionsEmulator(host, port);
      debugPrint('Using Firebase Functions Emulator at $host:$port');
    } catch (e) {
      debugPrint('Error setting up emulator: $e');
    }
  }
}
