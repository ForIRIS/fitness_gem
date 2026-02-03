import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fitness Gem'**
  String get appTitle;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Request'**
  String get permissionTitle;

  /// No description provided for @permissionGrantedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions Granted'**
  String get permissionGrantedTitle;

  /// No description provided for @permissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone access is required for pose analysis.'**
  String get permissionMessage;

  /// No description provided for @permissionGrantedMessage.
  ///
  /// In en, this message translates to:
  /// **'All permissions granted.\nPlease proceed to the next step.'**
  String get permissionGrantedMessage;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get previous;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @profileInfo.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInfo;

  /// No description provided for @profileDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your information for personalized workout recommendations.'**
  String get profileDescription;

  /// No description provided for @ageRange.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get ageRange;

  /// No description provided for @selectAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Select Age Range'**
  String get selectAgeRange;

  /// No description provided for @injuryHistory.
  ///
  /// In en, this message translates to:
  /// **'Injury History'**
  String get injuryHistory;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @neckShoulder.
  ///
  /// In en, this message translates to:
  /// **'Neck/Shoulder'**
  String get neckShoulder;

  /// No description provided for @lowerBack.
  ///
  /// In en, this message translates to:
  /// **'Lower Back'**
  String get lowerBack;

  /// No description provided for @knee.
  ///
  /// In en, this message translates to:
  /// **'Knee'**
  String get knee;

  /// No description provided for @ankle.
  ///
  /// In en, this message translates to:
  /// **'Ankle'**
  String get ankle;

  /// No description provided for @wrist.
  ///
  /// In en, this message translates to:
  /// **'Wrist'**
  String get wrist;

  /// No description provided for @elbow.
  ///
  /// In en, this message translates to:
  /// **'Elbow'**
  String get elbow;

  /// No description provided for @hip.
  ///
  /// In en, this message translates to:
  /// **'Hip'**
  String get hip;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @enterInjuryDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter injury details'**
  String get enterInjuryDetails;

  /// No description provided for @fitnessGoal.
  ///
  /// In en, this message translates to:
  /// **'Fitness Goal'**
  String get fitnessGoal;

  /// No description provided for @strengthBuilding.
  ///
  /// In en, this message translates to:
  /// **'Strength Building'**
  String get strengthBuilding;

  /// No description provided for @weightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get weightLoss;

  /// No description provided for @endurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get endurance;

  /// No description provided for @flexibility.
  ///
  /// In en, this message translates to:
  /// **'Flexibility'**
  String get flexibility;

  /// No description provided for @postureCorrection.
  ///
  /// In en, this message translates to:
  /// **'Posture Correction'**
  String get postureCorrection;

  /// No description provided for @rehabilitation.
  ///
  /// In en, this message translates to:
  /// **'Rehabilitation'**
  String get rehabilitation;

  /// No description provided for @enterGoalDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter your goal'**
  String get enterGoalDetails;

  /// No description provided for @experienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get experienceLevel;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner (< 1 year)'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate (1-3 years)'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced (3+ years)'**
  String get advanced;

  /// No description provided for @targetExercise.
  ///
  /// In en, this message translates to:
  /// **'Target Exercise'**
  String get targetExercise;

  /// No description provided for @selectExercise.
  ///
  /// In en, this message translates to:
  /// **'Select a target exercise'**
  String get selectExercise;

  /// No description provided for @safetySettings.
  ///
  /// In en, this message translates to:
  /// **'Safety Settings'**
  String get safetySettings;

  /// No description provided for @safetyDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure fall detection and emergency contacts.'**
  String get safetyDescription;

  /// No description provided for @enableFallDetection.
  ///
  /// In en, this message translates to:
  /// **'Enable Fall Detection'**
  String get enableFallDetection;

  /// No description provided for @fallDetectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Detects falls during exercise.'**
  String get fallDetectionDescription;

  /// No description provided for @guardianPhone.
  ///
  /// In en, this message translates to:
  /// **'Guardian Phone (Optional)'**
  String get guardianPhone;

  /// No description provided for @guardianPhoneDescription.
  ///
  /// In en, this message translates to:
  /// **'Phone number for emergency SMS alerts.'**
  String get guardianPhoneDescription;

  /// No description provided for @guardianStorageNotice.
  ///
  /// In en, this message translates to:
  /// **'This information is stored LOCALLY on your device for privacy.'**
  String get guardianStorageNotice;

  /// No description provided for @setUpLater.
  ///
  /// In en, this message translates to:
  /// **'Set up later'**
  String get setUpLater;

  /// No description provided for @disclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Disclaimer'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerMessage.
  ///
  /// In en, this message translates to:
  /// **'This app provides AI-based workout analysis but is not a medical device. Please consult a doctor before starting any exercise program.'**
  String get disclaimerMessage;

  /// No description provided for @agreeAndStart.
  ///
  /// In en, this message translates to:
  /// **'Agree and Start'**
  String get agreeAndStart;

  /// No description provided for @aiConsultant.
  ///
  /// In en, this message translates to:
  /// **'Talk with AI Consultant'**
  String get aiConsultant;

  /// No description provided for @aiConsultantDescription.
  ///
  /// In en, this message translates to:
  /// **'Get a more accurate personalized curriculum'**
  String get aiConsultantDescription;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Medical Disclaimer'**
  String get disclaimer;

  /// No description provided for @disclaimerContent.
  ///
  /// In en, this message translates to:
  /// **'This app does not provide medical advice.\nConsult a healthcare professional before exercising.\nStop immediately if you experience pain or injury.'**
  String get disclaimerContent;

  /// No description provided for @autoRedirect.
  ///
  /// In en, this message translates to:
  /// **'Redirecting in 3 seconds...'**
  String get autoRedirect;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @aiConsulting.
  ///
  /// In en, this message translates to:
  /// **'AI Consulting'**
  String get aiConsulting;

  /// No description provided for @aiConsultingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deep consultation for personalized curriculum'**
  String get aiConsultingSubtitle;

  /// No description provided for @reconsult.
  ///
  /// In en, this message translates to:
  /// **'Re-consult with AI Consultant'**
  String get reconsult;

  /// No description provided for @daysUntilReconsult.
  ///
  /// In en, this message translates to:
  /// **'{days} days until available'**
  String daysUntilReconsult(int days);

  /// No description provided for @weeklyLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You can consult once a week'**
  String get weeklyLimitMessage;

  /// No description provided for @aiConsultResult.
  ///
  /// In en, this message translates to:
  /// **'AI Consultation Result'**
  String get aiConsultResult;

  /// No description provided for @consultationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Consultation results updated.'**
  String get consultationUpdated;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone permissions were denied.\nPlease enable them in Settings.'**
  String get permissionDeniedMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @startWithAiConsultant.
  ///
  /// In en, this message translates to:
  /// **'Start After AI Consultation'**
  String get startWithAiConsultant;

  /// No description provided for @apiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API Key saved.'**
  String get apiKeySaved;

  /// No description provided for @guardianSaved.
  ///
  /// In en, this message translates to:
  /// **'Guardian contact saved.'**
  String get guardianSaved;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @experienceLevelShort.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get experienceLevelShort;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @appBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get appBuild;

  /// No description provided for @testCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera Test'**
  String get testCamera;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhone;

  /// No description provided for @enterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter API Key'**
  String get enterApiKey;

  /// No description provided for @saveApiKey.
  ///
  /// In en, this message translates to:
  /// **'Save API Key'**
  String get saveApiKey;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello, {age}-year-old {level} member!'**
  String welcomeMessage(String age, String level);

  /// No description provided for @welcomeTrainee.
  ///
  /// In en, this message translates to:
  /// **'Hello Trainee'**
  String get welcomeTrainee;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}'**
  String welcomeUser(String name);

  /// No description provided for @welcomeUserTier.
  ///
  /// In en, this message translates to:
  /// **'Hello {tier} Member {name}'**
  String welcomeUserTier(String tier, String name);

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname (Optional)'**
  String get nickname;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get enterNickname;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get aiChat;

  /// No description provided for @todayWorkout.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Workout'**
  String get todayWorkout;

  /// No description provided for @todayProgramDescFallback.
  ///
  /// In en, this message translates to:
  /// **'Follow your customized AI coaching plan.'**
  String get todayProgramDescFallback;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String estimatedTime(String minutes);

  /// No description provided for @generatingWorkout.
  ///
  /// In en, this message translates to:
  /// **'Generating workout.'**
  String get generatingWorkout;

  /// No description provided for @generationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate workout.\nPlease try again.'**
  String get generationFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @emptyProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'No Records Yet'**
  String get emptyProgressTitle;

  /// No description provided for @failedToLoadFeatured.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Featured Program'**
  String get failedToLoadFeatured;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user profile'**
  String get failedToLoadProfile;

  /// No description provided for @noRecordMessage.
  ///
  /// In en, this message translates to:
  /// **'Start your first workout to see stats'**
  String get noRecordMessage;

  /// No description provided for @medicalDisclaimerShort.
  ///
  /// In en, this message translates to:
  /// **'This app does not provide medical advice.\nStop immediately if you experience pain.'**
  String get medicalDisclaimerShort;

  /// No description provided for @aiChatInitialMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! What kind of workout would you like to do today?\nEx: \"I want a light lower body workout\", \"Focus on upper body\"'**
  String get aiChatInitialMessage;

  /// No description provided for @aiChatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a message...'**
  String get aiChatPlaceholder;

  /// No description provided for @replaceWithCurriculum.
  ///
  /// In en, this message translates to:
  /// **'Replace with this curriculum'**
  String get replaceWithCurriculum;

  /// No description provided for @curriculumRecommendation.
  ///
  /// In en, this message translates to:
  /// **'I recommend {title}!'**
  String curriculumRecommendation(String title);

  /// No description provided for @curriculumGenerationError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, failed to generate curriculum. Please try again.'**
  String get curriculumGenerationError;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errorOccurred(String error);

  /// No description provided for @viewDetail.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get viewDetail;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNow;

  /// No description provided for @workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete! 🎉'**
  String get workoutComplete;

  /// No description provided for @returnHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get returnHome;

  /// No description provided for @todayScore.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Score'**
  String get todayScore;

  /// No description provided for @scorePerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect! 🔥'**
  String get scorePerfect;

  /// No description provided for @scoreGreat.
  ///
  /// In en, this message translates to:
  /// **'Great! 💪'**
  String get scoreGreat;

  /// No description provided for @scoreGood.
  ///
  /// In en, this message translates to:
  /// **'Good! 👍'**
  String get scoreGood;

  /// No description provided for @scoreOk.
  ///
  /// In en, this message translates to:
  /// **'Okay! 😊'**
  String get scoreOk;

  /// No description provided for @scoreTryHard.
  ///
  /// In en, this message translates to:
  /// **'Try a bit harder!'**
  String get scoreTryHard;

  /// No description provided for @scoreNextTime.
  ///
  /// In en, this message translates to:
  /// **'You can do better next time!'**
  String get scoreNextTime;

  /// No description provided for @improvementPoints.
  ///
  /// In en, this message translates to:
  /// **'Improvement Points'**
  String get improvementPoints;

  /// No description provided for @scoreBySet.
  ///
  /// In en, this message translates to:
  /// **'Score by Set'**
  String get scoreBySet;

  /// No description provided for @repsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total reps'**
  String get repsTotal;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @workoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Workout Description'**
  String get workoutDescription;

  /// No description provided for @precautions.
  ///
  /// In en, this message translates to:
  /// **'Precautions'**
  String get precautions;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// No description provided for @downloadingResources.
  ///
  /// In en, this message translates to:
  /// **'Downloading required files...'**
  String get downloadingResources;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete!'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get ready;

  /// No description provided for @aiConsultantBanner.
  ///
  /// In en, this message translates to:
  /// **'I\'ll create a personalized curriculum with 3-5 questions'**
  String get aiConsultantBanner;

  /// No description provided for @aiProfileAnalysisBanner.
  ///
  /// In en, this message translates to:
  /// **'I\'ll analyze your profile again'**
  String get aiProfileAnalysisBanner;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error occurred'**
  String get networkError;

  /// No description provided for @completeAndStart.
  ///
  /// In en, this message translates to:
  /// **'Complete and Start'**
  String get completeAndStart;

  /// No description provided for @answerPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your answer...'**
  String get answerPlaceholder;

  /// No description provided for @enterApiKeyHackathon.
  ///
  /// In en, this message translates to:
  /// **'Enter API Key (Hackathon)'**
  String get enterApiKeyHackathon;

  /// No description provided for @apiKeyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Gemini API Key'**
  String get apiKeyDialogTitle;

  /// No description provided for @apiKeyDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'To avoid rate limits during the hackathon, please enter your own Gemini API Key.'**
  String get apiKeyDialogDescription;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// No description provided for @exerciseSquat.
  ///
  /// In en, this message translates to:
  /// **'Squat (Lower Body)'**
  String get exerciseSquat;

  /// No description provided for @exercisePushup.
  ///
  /// In en, this message translates to:
  /// **'Push-up (Upper Body)'**
  String get exercisePushup;

  /// No description provided for @exerciseLunge.
  ///
  /// In en, this message translates to:
  /// **'Lunge'**
  String get exerciseLunge;

  /// No description provided for @exercisePlank.
  ///
  /// In en, this message translates to:
  /// **'Plank (Core)'**
  String get exercisePlank;

  /// No description provided for @geminiApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Key'**
  String get geminiApiKeyTitle;

  /// No description provided for @hackathonEdition.
  ///
  /// In en, this message translates to:
  /// **'Hackathon Edition'**
  String get hackathonEdition;

  /// No description provided for @downloadAndStart.
  ///
  /// In en, this message translates to:
  /// **'Download & Start'**
  String get downloadAndStart;

  /// No description provided for @createWorkout.
  ///
  /// In en, this message translates to:
  /// **'Create Workout'**
  String get createWorkout;

  /// No description provided for @programs.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programs;

  /// No description provided for @dailyHotCategories.
  ///
  /// In en, this message translates to:
  /// **'Daily Hot Programs'**
  String get dailyHotCategories;

  /// No description provided for @readyToWorkout.
  ///
  /// In en, this message translates to:
  /// **'Ready to Workout'**
  String get readyToWorkout;

  /// No description provided for @welcomeReady.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get welcomeReady;

  /// No description provided for @pickAProgram.
  ///
  /// In en, this message translates to:
  /// **'Pick A Program'**
  String get pickAProgram;

  /// No description provided for @fullyCustomizableProgram.
  ///
  /// In en, this message translates to:
  /// **'Fully Customizable Program'**
  String get fullyCustomizableProgram;

  /// No description provided for @joinTheFlow.
  ///
  /// In en, this message translates to:
  /// **'Get Set, Stay\nIgnite, Finish Proud.\nJoin The Flow.'**
  String get joinTheFlow;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'HOLD'**
  String get hold;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection.'**
  String get errNetwork;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'Server response is delayed. Please try again later.'**
  String get errTimeout;

  /// No description provided for @errPermission.
  ///
  /// In en, this message translates to:
  /// **'Please grant the required permissions.'**
  String get errPermission;

  /// No description provided for @errCamera.
  ///
  /// In en, this message translates to:
  /// **'A problem occurred while accessing the camera.'**
  String get errCamera;

  /// No description provided for @errAiService.
  ///
  /// In en, this message translates to:
  /// **'A problem occurred with the AI service. Please try again later.'**
  String get errAiService;

  /// No description provided for @errStorage.
  ///
  /// In en, this message translates to:
  /// **'Insufficient storage space.'**
  String get errStorage;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'A problem occurred. Please try again.'**
  String get errUnknown;

  /// No description provided for @workoutWellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done today!'**
  String get workoutWellDone;

  /// No description provided for @continueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Let\'s keep it up tomorrow.'**
  String get continueTomorrow;

  /// No description provided for @resumeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Resume Workout'**
  String get resumeWorkout;

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume Workout?'**
  String get resumeTitle;

  /// No description provided for @resumeDesc.
  ///
  /// In en, this message translates to:
  /// **'Would you like to resume where you left off or start from the beginning?'**
  String get resumeDesc;

  /// No description provided for @resumeFromLast.
  ///
  /// In en, this message translates to:
  /// **'Resume from last'**
  String get resumeFromLast;

  /// No description provided for @startBeginning.
  ///
  /// In en, this message translates to:
  /// **'Start from beginning'**
  String get startBeginning;

  /// No description provided for @tomorrowWorkout.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s Workout'**
  String get tomorrowWorkout;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @signInSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up / Log In'**
  String get signInSignUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// No description provided for @guardianLoginMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to use Guardian features.'**
  String get guardianLoginMessage;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Authentication Error'**
  String get authError;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address format.'**
  String get invalidEmail;

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'This user has been disabled.'**
  String get userDisabled;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email.'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get wrongPassword;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak.'**
  String get weakPassword;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
