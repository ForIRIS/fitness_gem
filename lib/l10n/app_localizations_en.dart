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
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Back';

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
  String get startWithAiConsultant => 'Start After AI Consultation';

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
    return 'Hi $name';
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
  String get todayProgramDescFallback =>
      'Follow your customized AI coaching plan.';

  @override
  String estimatedTime(String minutes) {
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
  String get emptyProgressTitle => 'No Records Yet';

  @override
  String get failedToLoadFeatured => 'Failed to load Featured Program';

  @override
  String get failedToLoadProfile => 'Failed to load user profile';

  @override
  String get noRecordMessage => 'Start your first workout to see stats';

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
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get viewDetail => 'Details';

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
  String downloadFailed(String error) {
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

  @override
  String get geminiApiKeyTitle => 'Gemini API Key';

  @override
  String get hackathonEdition => 'Hackathon Edition';

  @override
  String get downloadAndStart => 'Download & Start';

  @override
  String get createWorkout => 'Create Workout';

  @override
  String get programs => 'Programs';

  @override
  String get dailyHotCategories => 'Daily Hot Programs';

  @override
  String get readyToWorkout => 'Ready to Workout';

  @override
  String get welcomeReady => 'You\'re All Set!';

  @override
  String get pickAProgram => 'Pick A Program';

  @override
  String get fullyCustomizableProgram => 'Fully Customizable Program';

  @override
  String get joinTheFlow =>
      'Get Set, Stay\nIgnite, Finish Proud.\nJoin The Flow.';

  @override
  String get members => 'Members';

  @override
  String get hold => 'HOLD';

  @override
  String get errNetwork => 'Please check your network connection.';

  @override
  String get errTimeout =>
      'Server response is delayed. Please try again later.';

  @override
  String get errPermission => 'Please grant the required permissions.';

  @override
  String get errCamera => 'A problem occurred while accessing the camera.';

  @override
  String get errAiService =>
      'A problem occurred with the AI service. Please try again later.';

  @override
  String get errStorage => 'Insufficient storage space.';

  @override
  String get errUnknown => 'A problem occurred. Please try again.';

  @override
  String get workoutWellDone => 'Well done today!';

  @override
  String get continueTomorrow => 'Let\'s keep it up tomorrow.';

  @override
  String get resumeWorkout => 'Resume Workout';

  @override
  String get resumeTitle => 'Resume Workout?';

  @override
  String get resumeDesc =>
      'Would you like to resume where you left off or start from the beginning?';

  @override
  String get resumeFromLast => 'Resume from last';

  @override
  String get startBeginning => 'Start from beginning';

  @override
  String get tomorrowWorkout => 'Tomorrow\'s Workout';

  @override
  String get completed => 'Completed';

  @override
  String get signInSignUp => 'Sign Up / Log In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get loginRequired => 'Login Required';

  @override
  String get guardianLoginMessage => 'Please sign in to use Guardian features.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get authError => 'Authentication Error';

  @override
  String get invalidEmail => 'Invalid email address format.';

  @override
  String get userDisabled => 'This user has been disabled.';

  @override
  String get userNotFound => 'No user found with this email.';

  @override
  String get wrongPassword => 'Incorrect password.';

  @override
  String get emailAlreadyInUse => 'This email is already registered.';

  @override
  String get weakPassword => 'The password is too weak.';

  @override
  String get unknownError => 'An unknown error occurred.';

  @override
  String get baselineTitle => 'PHYSICAL BASELINE';

  @override
  String get baselineMovementBenchmark => 'Movement Benchmark';

  @override
  String get baselineInstructions =>
      'To personalize your experience, please perform 3 moderate air squats. \n\nEnsure your head and feet are visible in the frame.';

  @override
  String get baselineImReady => 'I\'M READY';

  @override
  String get baselineFullBodyNotVisible => 'Full Body Not Visible';

  @override
  String get baselineMoveBack =>
      'Please move back until your feet are visible.';

  @override
  String get baselineHoldingPosition => 'Holding Position...';

  @override
  String get baselineRecording => 'RECORDING...';

  @override
  String get baselinePerformSquats => 'Perform 3 moderate air squats now';

  @override
  String get baselineAnalyzing => 'GEMINI ANALYZING...';

  @override
  String get baselineExtractingMarkers =>
      'Extracting mobility and stability markers';

  @override
  String get baselineSuccess => 'Assessment Success';

  @override
  String get baselineStability => 'STABILITY';

  @override
  String get baselineMobility => 'MOBILITY';

  @override
  String get baselineContinue => 'CONTINUE TO WORKOUT';

  @override
  String get baselineErrorTitle => 'Something went wrong';

  @override
  String get baselineTryAgainLater => 'TRY AGAIN LATER';

  @override
  String ttsWorkoutStart(String exerciseName) {
    return 'Starting $exerciseName workout. Please take your position.';
  }

  @override
  String ttsSetStart(int setNumber) {
    return 'Starting set $setNumber.';
  }

  @override
  String ttsRestStart(int seconds) {
    return 'Rest for $seconds seconds.';
  }

  @override
  String get ttsReadyPose => 'Please take the ready pose.';

  @override
  String get ttsWorkoutComplete => 'Workout complete. Great job!';

  @override
  String get ttsFallDetection =>
      'Are you okay? If there is no problem, please touch the screen.';

  @override
  String get ttsAnalyzing => 'Analyzing. Please wait a moment.';

  @override
  String get ttsBodyNotVisible =>
      'Please adjust the camera so your whole body is visible.';

  @override
  String ttsCountdown(int seconds) {
    return '$seconds';
  }

  @override
  String get ttsStart => 'Start!';

  @override
  String get ttsReady => 'Ready! Starting soon.';

  @override
  String get baselineTtsStart =>
      'We will now perform a quick physical assessment. Please stand back so your full body is visible.';

  @override
  String get baselineTtsPerformSquats =>
      'Please perform 3 moderate air squats.';

  @override
  String get baselineTtsComplete =>
      'Assessment complete. I have updated your physical profile.';

  @override
  String get baselineTtsError =>
      'An error occurred during assessment. Please try again.';

  @override
  String get errorCaptureFailed => 'Failed to capture assessment video';

  @override
  String errorAnalysisFailed(String message) {
    return 'Analysis failed: $message';
  }

  @override
  String onboardingStepPreview(int current, String stepName) {
    return 'Step $current of 6: $stepName';
  }

  @override
  String get aiInviteMessageComplete =>
      'I\'ve analyzed your goals! To customize your form correction, I recommend a quick 30-second mobility check.';

  @override
  String get aiInviteAssessmentButton => 'START ALIGNMENT CHECK';

  @override
  String get aiInviteAssessmentSkip => 'Skip for now';

  @override
  String get onboardingWelcomeTitle => 'Welcome to\nFitness Gem';

  @override
  String get onboardingWelcomeSubtitle =>
      'Your AI Fitness Journey starts here.';

  @override
  String get onboardingStep1Description =>
      'Tell us about yourself to tailor your experience.';

  @override
  String get onboardingStep2Description =>
      'Consult with Gemini via voice to build your plan.';

  @override
  String get onboardingStep3Description =>
      'A 30-second camera check to perfect your form.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get micPermissionReason =>
      'Microphone access is needed for AI voice chat and emergency detection.';

  @override
  String get cameraPermissionReason =>
      'Camera access is needed for AI physical alignment and pose analysis.';

  @override
  String get listening => 'Listening...';

  @override
  String get typeMessageHint => 'Type a message...';

  @override
  String get assessmentRecommended => 'Physical Assessment Recommended';

  @override
  String get assessmentRecommendedDesc => 'Let\'s check your form level.';

  @override
  String get interviewComplete => 'Interview Complete';

  @override
  String get safetyGuardianTitle => 'Safety Guardian';

  @override
  String get safetyGuardianDescription =>
      'Protect yourself with real-time AI safety monitoring.';

  @override
  String get benefitFallDetectionTitle => 'Fall Detection Available';

  @override
  String get benefitFallDetectionDesc =>
      'AI detects sudden drops during workouts.';

  @override
  String get benefitGuardianEmailTitle => 'Guardian Connection';

  @override
  String get benefitGuardianEmailDesc =>
      'Link via Guardian\'s email in Settings.';

  @override
  String get benefitEmergencyPushTitle => 'Emergency Protection';

  @override
  String get benefitEmergencyPushDesc =>
      'Push notifications sent to guardian if no response.';

  @override
  String get guardianEmailNotice =>
      'Your Guardian must also be a registered user. You can link them by entering their email address in Settings > Account.';

  @override
  String get emergencyFallSuspected => 'Fall Suspected?';

  @override
  String get emergencyAreYouOkay => 'Are you okay?';

  @override
  String get emergencyCheckingStatus => 'Checking your status...';

  @override
  String get emergencyPleaseRest => 'Please rest for a moment.';

  @override
  String get emergencyImOk => 'I\'M OK';

  @override
  String get emergencyTitle => 'EMERGENCY';

  @override
  String get emergencySubtitle => 'Fall detected. Help is on the way.';

  @override
  String get emergencySlideToCall => 'Slide to Call SOS';

  @override
  String get emergencyHoldToCancel => 'Hold to Cancel';

  @override
  String get emergencyTtsWarning => 'Emergency Detected. Help is on the way.';

  @override
  String emergencySmsBody(String name) {
    return '🚨 EMERGENCY: $name may have fallen during a workout. Please check on them immediately.';
  }

  @override
  String emergencyLocationLink(String url) {
    return 'Location: $url';
  }

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicyIntro =>
      'Your privacy is our priority. Here is how we handle your data:';

  @override
  String get privacyLocalTitle => 'Local Storage';

  @override
  String get privacyLocalDesc =>
      'Biometric data (Height/Weight/Gender) stays on your phone.';

  @override
  String get privacyGeminiTitle => 'Gemini Analysis';

  @override
  String get privacyGeminiDesc =>
      'Data is used for real-time analysis only. NOT used for training.';

  @override
  String get guardianPushPurpose => 'Used ONLY for fall detection alerts.';

  @override
  String get privacyMinimalTitle => 'Minimal Data';

  @override
  String get privacyMinimalDesc =>
      'We prioritize your privacy. No personal data is shared with third parties. Your email is used SOLELY for Guardian notifications and is deleted immediately upon account withdrawal.';

  @override
  String get confirmDeleteTitle => 'Are you sure?';

  @override
  String confirmDeleteMessage(String keyword) {
    return 'This action cannot be undone. To confirm, please type \"$keyword\" below.';
  }

  @override
  String typeToConfirm(String keyword) {
    return 'Type \"$keyword\"';
  }

  @override
  String get agreeKeyword => 'agree';

  @override
  String get delete => 'Delete';

  @override
  String get privacyAgreement => 'I have read and agree to the Privacy Policy.';

  @override
  String get genderTitle => 'How do you identify?';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderNonBinary => 'Non-binary';

  @override
  String get genderPreferNotToSay => 'Prefer not to say';

  @override
  String get profilePhotoTitle => 'Add a Profile Photo';

  @override
  String get profilePhotoDesc =>
      'This helps personalize your experience. It remains on your device.';

  @override
  String get photoPrivacyNote =>
      'Note: Your photo is stored locally and not shared with servers.';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get bodyStatsTitle => 'Body Measurements';

  @override
  String get bodyStatsDesc => 'Helps us calculate calories and track progress.';

  @override
  String get heightLabel => 'Height (cm)';

  @override
  String get height => 'Height';

  @override
  String get weightLabel => 'Weight (kg)';

  @override
  String get weight => 'Weight';

  @override
  String get metricUnit => 'Metric';

  @override
  String get imperialUnit => 'Imperial';

  @override
  String get justStart => 'Just Start';

  @override
  String get defaultNickname => 'Gemini User';

  @override
  String get defaultExercise => 'Full Body Workout';

  @override
  String get unitCm => 'cm';

  @override
  String get unitKg => 'kg';

  @override
  String get fitnessGoalsTitle => 'Your Fitness Goals';

  @override
  String get fitnessGoalsDesc => 'Select what you want to achieve.';

  @override
  String get fitnessGoalDesc => 'Select what you want to achieve.';

  @override
  String get goalLoseWeight => 'Lose Weight';

  @override
  String get goalBuildMuscle => 'Build Muscle';

  @override
  String get goalImproveEndurance => 'Improve Endurance';

  @override
  String get goalFlexibility => 'Flexibility';

  @override
  String get baselineRetry => 'RETRY';

  @override
  String get baselineSkipAssessment => 'SKIP ASSESSMENT';
}
