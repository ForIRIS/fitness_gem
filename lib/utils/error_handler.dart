import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// ErrorHandler - Common error handling utility
class ErrorHandler {
  /// Retry logic wrapper
  /// [action]: Async function to execute
  /// [maxRetries]: Maximum number of retries
  /// [delayMs]: Delay between retries (ms)
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

  /// Show error snackbar
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

  /// Show success snackbar
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

  /// Convert to user-friendly error message
  static String getUserFriendlyMessage(Object error, [BuildContext? context]) {
    final errorString = error.toString().toLowerCase();

    final l10n = context != null ? AppLocalizations.of(context) : null;

    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return l10n?.errNetwork ?? 'Please check your network connection.';
    }

    if (errorString.contains('timeout')) {
      return l10n?.errTimeout ??
          'Server response is delayed. Please try again later.';
    }

    if (errorString.contains('permission')) {
      return l10n?.errPermission ?? 'Please grant the required permissions.';
    }

    if (errorString.contains('camera')) {
      return l10n?.errCamera ??
          'A problem occurred while accessing the camera.';
    }

    if (errorString.contains('api') || errorString.contains('gemini')) {
      return l10n?.errAiService ??
          'A problem occurred with the AI service. Please try again later.';
    }

    if (errorString.contains('storage') || errorString.contains('disk')) {
      return l10n?.errStorage ?? 'Insufficient storage space.';
    }

    return l10n?.errUnknown ?? 'A problem occurred. Please try again.';
  }

  /// Show error dialog
  static Future<bool> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'OK',
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

  /// Show loading overlay
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
