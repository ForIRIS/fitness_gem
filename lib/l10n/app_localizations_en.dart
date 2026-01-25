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
  String get guardianStorageNotice =>
      'This information is stored LOCALLY on your device for privacy.';

  @override
  String get setUpLater => 'Set up later';

  @override
  String get disclaimerTitle => 'Medical Disclaimer';

  @override
  String get disclaimerMessage =>
      'This app provides AI-based workout analysis but is not a medical device. Please consult a doctor before starting any exercise program.';

  @override
  String get agreeAndStart => 'Agree and Start';

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
  String get reconsult => 'Re-consult with AI Consultant';

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

  @override
  String get startWithAiConsultant => 'Start after talking with AI Consultant';

  @override
  String get apiKeySaved => 'API Key saved.';

  @override
  String get guardianSaved => 'Guardian contact saved.';

  @override
  String get age => 'Age';

  @override
  String get experienceLevelShort => 'Experience Level';

  @override
  String get goal => 'Goal';

  @override
  String get appVersion => 'Version';

  @override
  String get appBuild => 'Build';

  @override
  String get testCamera => 'Camera Test';

  @override
  String get enterPhone => 'Enter phone number';

  @override
  String get enterApiKey => 'Enter API Key';

  @override
  String get saveApiKey => 'Save API Key';

  @override
  String welcomeMessage(String age, String level) {
    return 'Hello, $age-year-old $level member!';
  }

  @override
  String get welcomeTrainee => 'Hello Trainee';

  @override
  String welcomeUser(String name) {
    return 'Hello $name';
  }

  @override
  String welcomeUserTier(String tier, String name) {
    return 'Hello $tier Member $name';
  }

  @override
  String get nickname => 'Nickname (Optional)';

  @override
  String get enterNickname => 'Enter your nickname';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get aiChat => 'Chat';

  @override
  String get todayWorkout => 'Today\'s Workout';

  @override
  String estimatedTime(Object minutes) {
    return '~$minutes min';
  }

  @override
  String get generatingWorkout => 'Generating workout.';

  @override
  String get generationFailed =>
      'Failed to generate workout.\nPlease try again.';

  @override
  String get retry => 'Retry';

  @override
  String get progress => 'Progress';

  @override
  String get noRecordMessage =>
      'Graph will appear as you build exercise records';

  @override
  String get medicalDisclaimerShort =>
      'This app does not provide medical advice.\nStop immediately if you experience pain.';

  @override
  String get aiChatInitialMessage =>
      'Hello! What kind of workout would you like to do today?\nEx: \"I want a light lower body workout\", \"Focus on upper body\"';

  @override
  String get aiChatPlaceholder => 'Enter a message...';

  @override
  String get replaceWithCurriculum => 'Replace with this curriculum';

  @override
  String curriculumRecommendation(String title) {
    return 'I recommend $title!';
  }

  @override
  String get curriculumGenerationError =>
      'Sorry, failed to generate curriculum. Please try again.';

  @override
  String errorOccurred(Object error) {
    return 'An error occurred: $error';
  }

  @override
  String get viewDetail => 'View Details';

  @override
  String get startNow => 'Start Now';

  @override
  String get workoutComplete => 'Workout Complete! 🎉';

  @override
  String get returnHome => 'Return to Home';

  @override
  String get todayScore => 'Today\'s Score';

  @override
  String get scorePerfect => 'Perfect! 🔥';

  @override
  String get scoreGreat => 'Great! 💪';

  @override
  String get scoreGood => 'Good! 👍';

  @override
  String get scoreOk => 'Okay! 😊';

  @override
  String get scoreTryHard => 'Try a bit harder!';

  @override
  String get scoreNextTime => 'You can do better next time!';

  @override
  String get improvementPoints => 'Improvement Points';

  @override
  String get scoreBySet => 'Score by Set';

  @override
  String get repsTotal => 'Total reps';

  @override
  String get sets => 'Sets';

  @override
  String get workoutDescription => 'Workout Description';

  @override
  String get precautions => 'Precautions';

  @override
  String get preparing => 'Preparing...';

  @override
  String get downloadingResources => 'Downloading required files...';

  @override
  String get downloadComplete => 'Complete!';

  @override
  String downloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get ready => 'Ready!';

  @override
  String get aiConsultantBanner =>
      'I\'ll create a personalized curriculum with 3-5 questions';

  @override
  String get aiProfileAnalysisBanner => 'I\'ll analyze your profile again';

  @override
  String get networkError => 'Network error occurred';

  @override
  String get completeAndStart => 'Complete and Start';

  @override
  String get answerPlaceholder => 'Enter your answer...';

  @override
  String get enterApiKeyHackathon => 'Enter API Key (Hackathon)';

  @override
  String get apiKeyDialogTitle => 'Enter Gemini API Key';

  @override
  String get apiKeyDialogDescription =>
      'To avoid rate limits during the hackathon, please enter your own Gemini API Key.';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get exerciseSquat => 'Squat (Lower Body)';

  @override
  String get exercisePushup => 'Push-up (Upper Body)';

  @override
  String get exerciseLunge => 'Lunge';

  @override
  String get exercisePlank => 'Plank (Core)';
}
