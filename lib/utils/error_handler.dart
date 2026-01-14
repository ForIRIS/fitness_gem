import 'dart:async';
import 'package:flutter/material.dart';

/// ErrorHandler - 공통 에러 핸들링 유틸리티
class ErrorHandler {
  /// 재시도 로직 래퍼
  /// [action]: 실행할 비동기 함수
  /// [maxRetries]: 최대 재시도 횟수
  /// [delay]: 재시도 간격 (ms)
  static Future<T?> withRetry<T>({
    required Future<T> Function() action,
    int maxRetries = 3,
    int delayMs = 1000,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await action();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          debugPrint('ErrorHandler: All $maxRetries attempts failed');
          rethrow;
        }
        onRetry?.call(attempts, e);
        debugPrint('ErrorHandler: Attempt $attempts failed, retrying...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    return null;
  }

  /// 에러 스낵바 표시
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  /// 성공 스낵바 표시
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: duration,
      ),
    );
  }

  /// 사용자 친화적 에러 메시지 변환
  static String getUserFriendlyMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return '네트워크 연결을 확인해주세요.';
    }

    if (errorString.contains('timeout')) {
      return '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.';
    }

    if (errorString.contains('permission')) {
      return '필요한 권한을 허용해주세요.';
    }

    if (errorString.contains('camera')) {
      return '카메라 접근에 문제가 발생했습니다.';
    }

    if (errorString.contains('api') || errorString.contains('gemini')) {
      return 'AI 서비스에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    if (errorString.contains('storage') || errorString.contains('disk')) {
      return '저장 공간이 부족합니다.';
    }

    return '문제가 발생했습니다. 다시 시도해주세요.';
  }

  /// 에러 다이얼로그 표시
  static Future<bool> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '확인',
    String? cancelText,
    VoidCallback? onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              onConfirm?.call();
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 로딩 오버레이 표시
  static OverlayEntry? _loadingOverlay;

  static void showLoading(BuildContext context, {String? message}) {
    _loadingOverlay?.remove();

    _loadingOverlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message, style: const TextStyle(color: Colors.white70)),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_loadingOverlay!);
  }

  static void hideLoading() {
    _loadingOverlay?.remove();
    _loadingOverlay = null;
  }
}
