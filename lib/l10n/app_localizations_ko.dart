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
  String get skip => '건너뛰기 (기능 제한됨)';

  @override
  String get next => '다음';

  @override
  String get previous => '이전';

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
  String get setUpLater => '나중에 설정할게요';

  @override
  String get aiConsultant => 'AI Consultant와 대화';

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
  String get reconsult => '다시 상담받기';

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
}
