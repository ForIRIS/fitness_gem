// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fitness Gem';

  @override
  String get permissionTitle => 'Permission Request';

  @override
  String get permissionGrantedTitle => 'Permissions Granted';

  @override
  String get permissionMessage =>
      'Camera and microphone access is required for pose analysis.';

  @override
  String get permissionGrantedMessage =>
      'All permissions granted.\nPlease proceed to the next step.';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get skip => 'Skip (Limited Features)';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get start => 'Start';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get profileInfo => 'Profile Information';

  @override
  String get profileDescription =>
      'Enter your information for personalized workout recommendations.';

  @override
  String get ageRange => 'Age Range';

  @override
  String get selectAgeRange => 'Select Age Range';

  @override
  String get injuryHistory => 'Injury History';

  @override
  String get none => 'None';

  @override
  String get neckShoulder => 'Neck/Shoulder';

  @override
  String get lowerBack => 'Lower Back';

  @override
  String get knee => 'Knee';

  @override
  String get ankle => 'Ankle';

  @override
  String get wrist => 'Wrist';

  @override
  String get elbow => 'Elbow';

  @override
  String get hip => 'Hip';

  @override
  String get other => 'Other';

  @override
  String get enterInjuryDetails => 'Enter injury details';

  @override
  String get fitnessGoal => 'Fitness Goal';

  @override
  String get strengthBuilding => 'Strength Building';

  @override
  String get weightLoss => 'Weight Loss';

  @override
  String get endurance => 'Endurance';

  @override
  String get flexibility => 'Flexibility';

  @override
  String get postureCorrection => 'Posture Correction';

  @override
  String get rehabilitation => 'Rehabilitation';

  @override
  String get enterGoalDetails => 'Enter your goal';

  @override
  String get experienceLevel => 'Experience Level';

  @override
  String get beginner => 'Beginner (< 1 year)';

  @override
  String get intermediate => 'Intermediate (1-3 years)';

  @override
  String get advanced => 'Advanced (3+ years)';

  @override
  String get targetExercise => 'Target Exercise';

  @override
  String get selectExercise => 'Select a target exercise';

  @override
  String get safetySettings => 'Safety Settings';

  @override
  String get safetyDescription =>
      'Configure fall detection and emergency contacts.';

  @override
  String get enableFallDetection => 'Enable Fall Detection';

  @override
  String get fallDetectionDescription => 'Detects falls during exercise.';

  @override
  String get guardianPhone => 'Guardian Phone (Optional)';

  @override
  String get guardianPhoneDescription =>
      'Phone number for emergency SMS alerts.';

  @override
  String get setUpLater => 'Set up later';

  @override
  String get aiConsultant => 'Talk with AI Consultant';

  @override
  String get aiConsultantDescription =>
      'Get a more accurate personalized curriculum';

  @override
  String get disclaimer => '⚠️ Medical Disclaimer';

  @override
  String get disclaimerContent =>
      'This app does not provide medical advice.\nConsult a healthcare professional before exercising.\nStop immediately if you experience pain or injury.';

  @override
  String get autoRedirect => 'Redirecting in 3 seconds...';

  @override
  String get settings => 'Settings';

  @override
  String get aiConsulting => 'AI Consulting';

  @override
  String get aiConsultingSubtitle =>
      'Deep consultation for personalized curriculum';

  @override
  String get reconsult => 'Reconsult';

  @override
  String daysUntilReconsult(int days) {
    return '$days days until available';
  }

  @override
  String get weeklyLimitMessage => 'You can consult once a week';

  @override
  String get aiConsultResult => 'AI Consultation Result';

  @override
  String get consultationUpdated => 'Consultation results updated.';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionDeniedMessage =>
      'Camera and microphone permissions were denied.\nPlease enable them in Settings.';

  @override
  String get openSettings => 'Open Settings';
}
