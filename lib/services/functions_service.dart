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

  /// 운동 정보 상세 요청 (썸네일, 비디오 등) - Batch 처리
  Future<List<Map<String, dynamic>>> requestTaskInfo(
    List<String> taskIds,
  ) async {
    if (taskIds.isEmpty) return [];

    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'requestTaskInfo',
      );
      // "task_ids": [...]
      final results = await callable.call({'task_ids': taskIds});

      final data = results.data as Map<dynamic, dynamic>;
      final taskUrls = data['task_urls'] as List<dynamic>?;

      if (taskUrls == null) return [];

      return taskUrls.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error (requestTaskInfo): ${e.code}');
      // 인증 실패 등의 에러 처리 가능
      return [];
    } catch (e) {
      debugPrint('Error calling requestTaskInfo: $e');
      return [];
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
