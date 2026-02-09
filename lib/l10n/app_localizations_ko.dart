// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '피트니스 젬';

  @override
  String get permissionTitle => '권한 요청';

  @override
  String get permissionGrantedTitle => '권한 확인 완료';

  @override
  String get permissionMessage => '자세 분석을 위해 카메라와 마이크\n접근 권한이 필요합니다.';

  @override
  String get permissionGrantedMessage => '모든 권한이 허용되었습니다.\n다음 단계로 이동해주세요.';

  @override
  String get grantPermission => '권한 허용';

  @override
  String get skip => '건너뛰기';

  @override
  String get next => '다음';

  @override
  String get previous => '뒤로가기';

  @override
  String get start => '시작하기';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get save => '저장';

  @override
  String get close => '닫기';

  @override
  String get profileInfo => '프로필 정보';

  @override
  String get profileDescription => '맞춤 운동 추천을 위해 정보를 입력해주세요.';

  @override
  String get ageRange => '나이대';

  @override
  String get selectAgeRange => '나이대 선택';

  @override
  String get injuryHistory => '부상 이력';

  @override
  String get none => '없음';

  @override
  String get neckShoulder => '목/어깨';

  @override
  String get lowerBack => '허리';

  @override
  String get knee => '무릎';

  @override
  String get ankle => '발목';

  @override
  String get wrist => '손목';

  @override
  String get elbow => '팔꿈치';

  @override
  String get hip => '고관절';

  @override
  String get other => '기타';

  @override
  String get enterInjuryDetails => '부상 부위를 입력하세요';

  @override
  String get fitnessGoal => '운동 목표';

  @override
  String get strengthBuilding => '근력 강화';

  @override
  String get weightLoss => '체중 감량';

  @override
  String get endurance => '체력 향상';

  @override
  String get flexibility => '유연성 향상';

  @override
  String get postureCorrection => '자세 교정';

  @override
  String get rehabilitation => '재활 운동';

  @override
  String get enterGoalDetails => '운동 목표를 입력하세요';

  @override
  String get experienceLevel => '운동 경험';

  @override
  String get beginner => '입문 (1년 미만)';

  @override
  String get intermediate => '중급 (1~3년)';

  @override
  String get advanced => '고급 (3년 이상)';

  @override
  String get targetExercise => '타겟 운동';

  @override
  String get selectExercise => '타겟 운동을 선택하세요';

  @override
  String get safetySettings => '안전 설정';

  @override
  String get safetyDescription => '낙상 감지 및 비상 연락처를 설정합니다.';

  @override
  String get enableFallDetection => '낙상 감지 기능 사용';

  @override
  String get fallDetectionDescription => '운동 중 넘어짐을 감지합니다.';

  @override
  String get guardianPhone => '보호자 전화번호 (선택)';

  @override
  String get guardianPhoneDescription => '비상 시 SMS 알림을 보낼 번호입니다.';

  @override
  String get guardianStorageNotice => '이 정보는 개인정보 보호를 위해 기기에만 저장됩니다.';

  @override
  String get setUpLater => '나중에 설정할게요';

  @override
  String get disclaimerTitle => '의료 면책 조항';

  @override
  String get disclaimerMessage =>
      '이 앱은 AI 기반 운동 분석을 제공하지만 의료 기기가 아닙니다. 운동 프로그램을 시작하기 전에 의사와 상담하십시오.';

  @override
  String get agreeAndStart => '동의하고 시작하기';

  @override
  String get aiConsultant => 'AI 컨설턴트와 상담하기';

  @override
  String get aiConsultantDescription => '더 정확한 맞춤 커리큘럼을 받을 수 있어요';

  @override
  String get disclaimer => '⚠️ 의료 조언 면책';

  @override
  String get disclaimerContent =>
      '본 앱은 의료 조언을 제공하지 않습니다.\n운동 전 전문 의료진과 상담하세요.\n부상이나 통증 발생 시 즉시 운동을 중단하세요.';

  @override
  String get autoRedirect => '3초 후 자동으로 넘어갑니다...';

  @override
  String get settings => '설정';

  @override
  String get aiConsulting => 'AI 컨설팅';

  @override
  String get aiConsultingSubtitle => '맞춤 커리큘럼을 위한 심층 상담';

  @override
  String get reconsult => 'AI 컨설턴트와 다시 상담받기';

  @override
  String daysUntilReconsult(int days) {
    return '$days일 후 가능';
  }

  @override
  String get weeklyLimitMessage => '일주일에 한 번 상담을 받을 수 있어요';

  @override
  String get aiConsultResult => 'AI 상담 결과';

  @override
  String get consultationUpdated => '상담 결과가 업데이트되었습니다.';

  @override
  String get permissionRequired => '권한 필요';

  @override
  String get permissionDeniedMessage =>
      '카메라와 마이크 권한이 거부되었습니다.\n설정에서 직접 권한을 허용해주세요.';

  @override
  String get openSettings => '설정 열기';

  @override
  String get startWithAiConsultant => 'AI 컨설턴트와 상담 후 시작하기';

  @override
  String get apiKeySaved => 'API Key가 저장되었습니다.';

  @override
  String get guardianSaved => '보호자 연락처가 저장되었습니다.';

  @override
  String get age => '나이';

  @override
  String get experienceLevelShort => '경험 수준';

  @override
  String get goal => '목표';

  @override
  String get appVersion => '버전';

  @override
  String get appBuild => '빌드';

  @override
  String get testCamera => '카메라 테스트';

  @override
  String get enterPhone => '전화번호 입력';

  @override
  String get enterApiKey => 'API Key 입력';

  @override
  String get saveApiKey => 'API Key 저장';

  @override
  String welcomeMessage(String age, String level) {
    return '안녕하세요, $age세 $level 회원님!';
  }

  @override
  String get welcomeTrainee => '안녕하세요, 연습생님!';

  @override
  String welcomeUser(String name) {
    return '안녕하세요, $name님!';
  }

  @override
  String welcomeUserTier(String tier, String name) {
    return '안녕하세요, $tier 멤버 $name님!';
  }

  @override
  String get nickname => '닉네임 (선택)';

  @override
  String get enterNickname => '닉네임을 입력하세요';

  @override
  String get startWorkout => '운동 시작';

  @override
  String get aiChat => '상담';

  @override
  String get todayWorkout => '오늘의 운동';

  @override
  String get todayProgramDescFallback => 'AI 맞춤 코칭 계획에 따라 운동을 진행하세요.';

  @override
  String estimatedTime(String minutes) {
    return '약 $minutes분';
  }

  @override
  String get generatingWorkout => '운동 생성 중...';

  @override
  String get generationFailed => '운동 생성에 실패했습니다.\n다시 시도해주세요.';

  @override
  String get retry => '다시 시도';

  @override
  String get progress => '진척도';

  @override
  String get emptyProgressTitle => '아직 기록이 없어요';

  @override
  String get failedToLoadFeatured => '추천 프로그램을 불러오지 못했습니다.';

  @override
  String get failedToLoadProfile => '사용자 프로필을 불러오지 못했습니다.';

  @override
  String get noRecordMessage => '운동을 시작하고 데이터를 쌓아보세요';

  @override
  String get medicalDisclaimerShort =>
      '본 앱은 의료 조언을 제공하지 않습니다.\n부상 시 즉시 운동을 중단하세요.';

  @override
  String get aiChatInitialMessage =>
      '안녕하세요! 오늘은 어떤 운동을 하고 싶으신가요?\n예: \"가볍게 하체 운동 하고 싶어\", \"상체 위주로 해줘\"';

  @override
  String get aiChatPlaceholder => '메시지를 입력하세요...';

  @override
  String get replaceWithCurriculum => '이 커리큘럼으로 교체';

  @override
  String curriculumRecommendation(String title) {
    return '$title을 추천드립니다!';
  }

  @override
  String get curriculumGenerationError => '죄송합니다, 커리큘럼을 생성하지 못했습니다. 다시 시도해주세요.';

  @override
  String errorOccurred(String error) {
    return '오류가 발생했습니다: $error';
  }

  @override
  String get viewDetail => '상세 보기';

  @override
  String get startNow => '바로 시작';

  @override
  String get workoutComplete => '운동 완료! 🎉';

  @override
  String get returnHome => '홈으로 돌아가기';

  @override
  String get todayScore => '오늘의 점수';

  @override
  String get scorePerfect => '완벽해요! 🔥';

  @override
  String get scoreGreat => '훌륭해요! 💪';

  @override
  String get scoreGood => '좋아요! 👍';

  @override
  String get scoreOk => '괜찮아요! 😊';

  @override
  String get scoreTryHard => '조금 더 노력해봐요!';

  @override
  String get scoreNextTime => '다음엔 더 잘할 수 있어요!';

  @override
  String get improvementPoints => '개선 포인트';

  @override
  String get scoreBySet => '세트별 점수';

  @override
  String get repsTotal => '총 reps';

  @override
  String get sets => '세트';

  @override
  String get workoutDescription => '운동 설명';

  @override
  String get precautions => '주의사항';

  @override
  String get preparing => '준비 작업 중...';

  @override
  String get downloadingResources => '필요한 파일을 다운로드 중입니다...';

  @override
  String get downloadComplete => '완료되었습니다!';

  @override
  String downloadFailed(String error) {
    return '다운로드 실패: $error';
  }

  @override
  String get ready => '준비 완료!';

  @override
  String get aiConsultantBanner => '3~5개의 질문으로 맞춤 커리큘럼을 만들어 드릴게요';

  @override
  String get aiProfileAnalysisBanner => '프로필을 다시 분석해 드릴게요';

  @override
  String get networkError => '네트워크 오류가 발생했습니다';

  @override
  String get completeAndStart => '완료하고 시작하기';

  @override
  String get answerPlaceholder => '답변을 입력하세요...';

  @override
  String get enterApiKeyHackathon => 'API 키 입력 (해커톤용)';

  @override
  String get apiKeyDialogTitle => 'Gemini API 키 입력';

  @override
  String get apiKeyDialogDescription =>
      '해커톤 테스트 중 Rate Limit을 피하기 위해 본인의 API 키를 입력해주세요.';

  @override
  String get apiKeyLabel => 'API 키';

  @override
  String get exerciseSquat => '하체 (스쿼트)';

  @override
  String get exercisePushup => '상체 (푸시업)';

  @override
  String get exerciseLunge => '런지';

  @override
  String get exercisePlank => '코어 (플랭크)';

  @override
  String get geminiApiKeyTitle => 'Gemini API Key';

  @override
  String get hackathonEdition => '해커톤 에디션';

  @override
  String get downloadAndStart => '다운로드 후 시작';

  @override
  String get createWorkout => '운동 생성하기';

  @override
  String get programs => '프로그램';

  @override
  String get dailyHotCategories => '실시간 인기 프로그램';

  @override
  String get readyToWorkout => '운동 준비 완료';

  @override
  String get welcomeReady => '준비가 되었습니다!';

  @override
  String get pickAProgram => '프로그램 선택';

  @override
  String get fullyCustomizableProgram => '커스텀 프로그램';

  @override
  String get joinTheFlow => '내 몸의 변화를\n피트니스 젬과 함께.\n지금 시작하세요.';

  @override
  String get members => '회원';

  @override
  String get hold => '유지';

  @override
  String get errNetwork => '네트워크 연결을 확인해주세요.';

  @override
  String get errTimeout => '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get errPermission => '필요한 권한을 허용해주세요.';

  @override
  String get errCamera => '카메라 접근에 문제가 발생했습니다.';

  @override
  String get errAiService => 'AI 서비스에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get errStorage => '저장 공간이 부족합니다.';

  @override
  String get errUnknown => '문제가 발생했습니다. 다시 시도해주세요.';

  @override
  String get workoutWellDone => '오늘도 수고하셨어요!';

  @override
  String get continueTomorrow => '내일도 함께 운동해요.';

  @override
  String get resumeWorkout => '운동 이어하기';

  @override
  String get resumeTitle => '이전 운동을 이어하시겠습니까?';

  @override
  String get resumeDesc => '중단했던 부분부터 시작할까요, 아니면 처음부터 다시 시작할까요?';

  @override
  String get resumeFromLast => '마지막부터 이어하기';

  @override
  String get startBeginning => '처음부터 시작하기';

  @override
  String get tomorrowWorkout => '내일의 운동';

  @override
  String get completed => '완료됨';

  @override
  String get signInSignUp => '회원가입 / 로그인';

  @override
  String get signOut => '로그아웃';

  @override
  String get deleteAccount => '회원 탈퇴';

  @override
  String get deleteAccountConfirm => '정말 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get loginRequired => '로그인 필요';

  @override
  String get guardianLoginMessage => '보호자 기능을 사용하려면 로그인이 필요합니다.';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get signIn => '로그인';

  @override
  String get signUp => '회원가입';

  @override
  String get passwordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get fieldRequired => '필수 항목입니다';

  @override
  String get authError => '인증 오류';

  @override
  String get invalidEmail => '이메일 형식이 올바르지 않습니다.';

  @override
  String get userDisabled => '사용이 중지된 계정입니다.';

  @override
  String get userNotFound => '해당 이메일로 가입된 사용자가 없습니다.';

  @override
  String get wrongPassword => '비밀번호가 틀렸습니다.';

  @override
  String get emailAlreadyInUse => '이미 사용 중인 이메일입니다.';

  @override
  String get weakPassword => '비밀번호가 너무 취약합니다.';

  @override
  String get unknownError => '알 수 없는 오류가 발생했습니다.';

  @override
  String get baselineTitle => '신체 능력 측정';

  @override
  String get baselineMovementBenchmark => '동작 벤치마크';

  @override
  String get baselineInstructions =>
      '개인 맞춤형 경험을 위해 10초 동안 스쿼트를 수행해주세요.\n\n머리부터 발끝까지 화면에 보이도록 해주세요.';

  @override
  String get baselineImReady => '준비 완료';

  @override
  String get baselineFullBodyNotVisible => '전신이 보이지 않습니다';

  @override
  String get baselineMoveBack => '발이 보일 때까지 뒤로 물러나주세요.';

  @override
  String get baselineHoldingPosition => '자세 유지 중...';

  @override
  String get baselineRecording => '녹화 중...';

  @override
  String get baselinePerformSquats => '10초 동안 스쿼트를 수행해주세요';

  @override
  String get baselineAnalyzing => 'GEMINI 분석 중...';

  @override
  String get baselineExtractingMarkers => '유연성 및 안정성 지표 추출 중';

  @override
  String get baselineSuccess => '측정 성공';

  @override
  String get baselineStability => '안정성';

  @override
  String get baselineMobility => '유연성';

  @override
  String get baselineContinue => '운동 하러 가기';

  @override
  String get baselineErrorTitle => '문제가 발생했습니다';

  @override
  String get baselineTryAgainLater => '나중에 다시 시도';

  @override
  String ttsWorkoutStart(String exerciseName) {
    return '$exerciseName 운동을 시작합니다. 준비 자세를 취해주세요.';
  }

  @override
  String ttsSetStart(int setNumber) {
    return '$setNumber세트를 시작합니다.';
  }

  @override
  String ttsRestStart(int seconds) {
    return '$seconds초간 휴식하세요.';
  }

  @override
  String get ttsReadyPose => '준비 자세를 취해주세요.';

  @override
  String get ttsWorkoutComplete => '운동이 완료되었습니다. 수고하셨습니다!';

  @override
  String get ttsFallDetection => '괜찮으신가요? 문제가 없다면 화면을 터치해주세요.';

  @override
  String get ttsAnalyzing => '분석 중입니다. 잠시만 기다려주세요.';

  @override
  String get ttsBodyNotVisible => '전신이 보이도록 카메라를 조절해주세요.';

  @override
  String ttsCountdown(int seconds) {
    return '$seconds';
  }

  @override
  String get ttsStart => '시작!';

  @override
  String get ttsReady => '준비! 곧 시작합니다.';

  @override
  String get baselineTtsStart => '지금부터 신체 능력 측정을 시작합니다. 전신이 보이도록 뒤로 물러나주세요.';

  @override
  String get baselineTtsPerformSquats => '10초 동안 스쿼트를 수행해주세요.';

  @override
  String get baselineTtsComplete => '측정이 완료되었습니다. 사용자의 신체 프로필을 업데이트했습니다.';

  @override
  String get baselineTtsError => '측정 중 오류가 발생했습니다. 다시 시도해주세요.';

  @override
  String get errorCaptureFailed => '측정 영상 캡처에 실패했습니다.';

  @override
  String errorAnalysisFailed(String message) {
    return '분석 실패: $message';
  }

  @override
  String onboardingStepPreview(int current, String stepName) {
    return '총 6단계 중 $current단계: $stepName';
  }

  @override
  String get aiInviteMessageComplete =>
      '목표 분석이 완료되었습니다! 더 정확한 자세 교정을 위해 30초 움직임 측정을 추천합니다.';

  @override
  String get aiInviteAssessmentButton => '자세 측정 시작하기';

  @override
  String get aiInviteAssessmentSkip => '나중에 하기';

  @override
  String get onboardingWelcomeTitle => 'Fitness Gem에\n오신 것을 환영합니다';

  @override
  String get onboardingWelcomeSubtitle => 'AI와 함께하는 맞춤형 피트니스 여정';

  @override
  String get onboardingStep1Description => '더 나은 경험을 위해 프로필을 설정해주세요.';

  @override
  String get onboardingStep2Description => 'Gemini와 음성으로 상담하며 플랜을 만듭니다.';

  @override
  String get onboardingStep3Description => '30초 카메라 측정으로 자세를 교정받으세요.';

  @override
  String get getStarted => '시작하기';

  @override
  String get micPermissionReason => 'AI 음성 채팅과 긴급 상황 감지를 위해 마이크 권한이 필요합니다.';

  @override
  String get cameraPermissionReason => 'AI 자세 교정 및 분석을 위해 카메라 권한이 필요합니다.';

  @override
  String get listening => '듣고 있어요...';

  @override
  String get typeMessageHint => '메시지를 입력하세요...';

  @override
  String get assessmentRecommended => '신체 측정 권장';

  @override
  String get assessmentRecommendedDesc => '자세 레벨을 확인해보세요.';

  @override
  String get interviewComplete => '상담 완료';

  @override
  String get safetyGuardianTitle => '안전 가디언';

  @override
  String get safetyGuardianDescription => 'AI 실시간 모니터링으로 안전하게 운동하세요.';

  @override
  String get benefitFallDetectionTitle => '낙상 감지 지원';

  @override
  String get benefitFallDetectionDesc => '운동 중 갑작스러운 넘어짐을 AI가 감지합니다.';

  @override
  String get benefitGuardianEmailTitle => '보호자 연결';

  @override
  String get benefitGuardianEmailDesc => '설정에서 보호자의 이메일로 연결하세요.';

  @override
  String get benefitEmergencyPushTitle => '비상 상황 보호';

  @override
  String get benefitEmergencyPushDesc => '응답이 없을 경우 보호자에게 푸시 알림을 보냅니다.';

  @override
  String get guardianEmailNotice =>
      '보호자분도 가입된 사용자여야 합니다. 설정 > 계정에서 보호자의 이메일 주소를 입력하여 연결할 수 있습니다.';

  @override
  String get emergencyFallSuspected => '넘어짐이 감지되었나요?';

  @override
  String get emergencyAreYouOkay => '괜찮으신가요?';

  @override
  String get emergencyCheckingStatus => '상태를 확인하고 있습니다...';

  @override
  String get emergencyPleaseRest => '잠시만 안정을 취해 주세요.';

  @override
  String get emergencyImOk => '괜찮아요';

  @override
  String get emergencyTitle => '비상 상황';

  @override
  String get emergencySubtitle => '넘어짐이 감지되었습니다. 도움이 필요합니다.';

  @override
  String get emergencySlideToCall => '밀어서 SOS 호출';

  @override
  String get emergencyHoldToCancel => '길게 눌러 취소';

  @override
  String get emergencyTtsWarning => '비상 상황이 감지되었습니다. 도움이 필요합니다.';

  @override
  String emergencySmsBody(String name) {
    return '🚨 긴급 알림: $name님이 운동 중 넘어졌을 가능성이 있습니다. 즉시 확인해 주세요.';
  }

  @override
  String emergencyLocationLink(String url) {
    return '위치: $url';
  }

  @override
  String get privacyPolicyTitle => '개인정보 처리방침';

  @override
  String get privacyPolicyIntro => '회원님의 개인정보 보호를 최우선으로 합니다:';

  @override
  String get privacyLocalTitle => '로컬 저장소';

  @override
  String get privacyLocalDesc => '신체 정보(키/몸무게/성별)는 기기에만 안전하게 저장됩니다.';

  @override
  String get privacyGeminiTitle => 'Gemini 분석';

  @override
  String get privacyGeminiDesc => '데이터는 실시간 분석에만 사용되며, 학습용으로 사용되지 않습니다.';

  @override
  String get guardianPushPurpose => '낙상 감지 알림 전송에만 사용됩니다.';

  @override
  String get privacyMinimalTitle => '최소한의 데이터';

  @override
  String get privacyMinimalDesc =>
      '개인 정보는 제3자와 공유되지 않습니다. 이메일은 보호자 알림용으로만 사용되며, 탈퇴 시 즉시 삭제됩니다.';

  @override
  String get confirmDeleteTitle => '정말 진행하시겠습니까?';

  @override
  String confirmDeleteMessage(String keyword) {
    return '이 작업은 되돌릴 수 없습니다. 확인하려면 아래에 \"$keyword\"를 입력하세요.';
  }

  @override
  String typeToConfirm(String keyword) {
    return '\"$keyword\" 입력';
  }

  @override
  String get agreeKeyword => '동의';

  @override
  String get delete => '삭제';

  @override
  String get privacyAgreement => '개인정보 처리방침을 확인하였으며 동의합니다.';

  @override
  String get genderTitle => '성별을 선택해주세요';

  @override
  String get genderMale => '남성';

  @override
  String get genderFemale => '여성';

  @override
  String get genderNonBinary => '논바이너리';

  @override
  String get genderPreferNotToSay => '공개 안 함';

  @override
  String get profilePhotoTitle => '프로필 사진 추가';

  @override
  String get profilePhotoDesc => '개인 맞춤형 경험을 제공합니다. 기기에만 저장됩니다.';

  @override
  String get photoPrivacyNote => '참고: 사진은 로컬에 저장되며 서버로 전송되지 않습니다.';

  @override
  String get removePhoto => '사진 삭제';

  @override
  String get takePhoto => '사진 촬영';

  @override
  String get chooseFromGallery => '갤러리에서 선택';

  @override
  String get bodyStatsTitle => '신체 치수';

  @override
  String get bodyStatsDesc => '칼로리 계산과 진행 상황 추적에 사용됩니다.';

  @override
  String get heightLabel => '키 (cm)';

  @override
  String get height => '키';

  @override
  String get weightLabel => '몸무게 (kg)';

  @override
  String get weight => '몸무게';

  @override
  String get metricUnit => '미터법';

  @override
  String get imperialUnit => '야드파운드법';

  @override
  String get justStart => '그냥 시작하기';

  @override
  String get defaultNickname => 'Gemini 사용자';

  @override
  String get defaultExercise => '전신 운동';

  @override
  String get unitCm => 'cm';

  @override
  String get unitKg => 'kg';

  @override
  String get fitnessGoalsTitle => '운동 목표';

  @override
  String get fitnessGoalsDesc => '달성하고자 하는 목표를 선택하세요.';

  @override
  String get fitnessGoalDesc => '달성하고자 하는 목표를 선택하세요.';

  @override
  String get goalLoseWeight => '체중 감량';

  @override
  String get goalBuildMuscle => '근육 증량';

  @override
  String get goalImproveEndurance => '지구력 향상';

  @override
  String get goalFlexibility => '유연성 향상';

  @override
  String get baselineRetry => '다시 시도';

  @override
  String get baselineSkipAssessment => '건너뛰기';
}
