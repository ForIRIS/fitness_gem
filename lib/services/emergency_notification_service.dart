import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Added
import '../domain/entities/user_profile.dart';

/// Service to trigger emergency notifications
class EmergencyNotificationService {
  /// Trigger notification based on platform and user preference
  Future<void> triggerEmergency(UserProfile profile) async {
    final method =
        profile.emergencyMethod ?? (Platform.isAndroid ? 'sms' : 'push');

    if (method == 'sms') {
      final guardianPhone = profile.guardianPhone;
      if (guardianPhone == null || guardianPhone.isEmpty) {
        debugPrint("Emergency Triggered (SMS), but no guardian phone set.");
        return;
      }
      await _sendAndroidSMS(guardianPhone, profile.nickname);
    } else {
      // Push Notification
      await _triggerBackendPushNotification(profile);
    }
  }

  /// Android: Send SMS via Intent
  Future<void> _sendAndroidSMS(String phone, String nickname) async {
    final message =
        "🚨 EMERGENCY: $nickname may have fallen during a workout. Please check on them immediately.";
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{'body': message},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint("Emergency SMS intent launched.");
      } else {
        debugPrint("Could not launch SMS intent.");
      }
    } catch (e) {
      debugPrint("Error launching SMS: $e");
    }
  }

  /// Trigger Backend Push Notification via Cloud Functions
  Future<void> _triggerBackendPushNotification(UserProfile profile) async {
    try {
      debugPrint("Triggering Cloud Function: notifyGuardian...");
      final result = await FirebaseFunctions.instance
          .httpsCallable('notifyGuardian')
          .call();
      debugPrint("Guardian Notified Successfully: ${result.data}");
    } catch (e) {
      debugPrint("Failed to notify guardian via Cloud Functions: $e");
    }
  }
}
