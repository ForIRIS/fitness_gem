import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// FunctionsService - Firebase Cloud Functions 호출 관리
class FunctionsService {
  static final FunctionsService _instance = FunctionsService._internal();
  factory FunctionsService() => _instance;
  FunctionsService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 서버 상태 확인 (테스트용)
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

  /// Hello World 호출 (테스트용)
  Future<Map<String, dynamic>?> callHelloWorld({String? name}) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('helloWorld');
      final results = await callable.call({'name': name ?? 'Flutter User'});

      debugPrint('Hello World Response: ${results.data}');
      return results.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('Error calling helloWorld: $e');
      return null;
    }
  }

  /// 운동 리소스 안전 요청 (Bundle Zip, Video 등)
  Future<List<Map<String, dynamic>>> getWorkoutAssets(
    List<String> taskIds,
  ) async {
    if (taskIds.isEmpty) return [];

    try {
      final results = await _functions.httpsCallable('getWorkoutAssets').call({
        'task_ids': taskIds,
      });

      final data = results.data as Map<dynamic, dynamic>;
      final assets = data['assets'] as List<dynamic>?;

      if (assets == null) return [];
      return assets.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Error calling getWorkoutAssets: $e');
      return [];
    }
  }

  /// Gemini 운동 분석 요청 (Proxy)
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

  /// 낙상 감지 AI 검증 요청
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

  /// 에뮬레이터 설정 (개발용)
  void useEmulator(String host, int port) {
    try {
      _functions.useFunctionsEmulator(host, port);
      debugPrint('Using Firebase Functions Emulator at $host:$port');
    } catch (e) {
      debugPrint('Error setting up emulator: $e');
    }
  }
}
