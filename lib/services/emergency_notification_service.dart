import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Added
import '../domain/entities/user_profile.dart';

/// Service to trigger emergency notifications
class EmergencyNotificationService {
  /// Trigger notification based on platform and user preference
  Future<void> triggerEmergency(UserProfile profile) async {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final method = profile.emergencyMethod ?? (isAndroid ? 'sms' : 'push');

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
    String message =
        "🚨 EMERGENCY: $nickname may have fallen during a workout. Please check on them immediately.";

    // Append Location
    final position = await _getCurrentLocation();
    if (position != null) {
      message +=
          "\nLocation: https://maps.google.com/?q=${position.latitude},${position.longitude}";
    }

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

  Future<Position?> _getCurrentLocation() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return null;
        }
        if (permission == LocationPermission.deniedForever) return null;

        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint("Error getting location: $e");
        return null;
      }
    }
    return null;
  }

  /// Trigger Backend Push Notification via Cloud Functions
  Future<void> _triggerBackendPushNotification(UserProfile profile) async {
    try {
      debugPrint("Triggering Cloud Function: notifyGuardian...");

      String? locationUrl;
      final position = await _getCurrentLocation();
      if (position != null) {
        locationUrl =
            "https://maps.google.com/?q=${position.latitude},${position.longitude}";
      }

      final result = await FirebaseFunctions.instance
          .httpsCallable('notifyGuardian')
          .call({'location': locationUrl});
      debugPrint("Guardian Notified Successfully: ${result.data}");
    } catch (e) {
      debugPrint("Failed to notify guardian via Cloud Functions: $e");
    }
  }
}
