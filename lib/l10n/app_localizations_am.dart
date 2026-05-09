// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'ባህር ሊንክ';

  @override
  String get tagline => 'ከተማዎ። ተገናኝቷል።';

  @override
  String get goodMorning => 'እንደምን አደሩ 👋';

  @override
  String get welcomeBack => 'እንኳን ደህና መጡ';

  @override
  String get locationCity => 'ባህር ዳር';

  @override
  String get liveReports => 'የቀጥታ ሪፖርቶች';

  @override
  String activeBadge(String count) {
    return '$count ንቁ';
  }

  @override
  String get emergencyAssist => 'የአደጋ ጊዜ እርዳታ';

  @override
  String get publicServices => 'የመንግስት አገልግሎቶች';

  @override
  String get seeAll => 'ሁሉንም ይመልከቱ';

  @override
  String get incidentReported => 'አደጋ ተመዝግቧል';

  @override
  String rewardLabel(String amount) {
    return '$amount ብር';
  }

  @override
  String get statusPending => 'በጥበቃ ላይ';

  @override
  String get statusInProgress => 'በሂደት ላይ';

  @override
  String get statusCompleted => 'ተጠናቋል';

  @override
  String get statusRejected => 'ተቀባይነት አላገኘም';

  @override
  String get statusResolved => 'ተፈትቷል';

  @override
  String get statusUnknown => 'ያልታወቀ';

  @override
  String get statusActive => 'ንቁ';

  @override
  String get myPublic => 'የእኔ';

  @override
  String get myEmergency => 'የእኔ አደጋ';

  @override
  String get serviceReports => 'የአገልግሎት ሪፖርቶች';

  @override
  String reportsCount(String count) {
    return '$count ሪፖርቶች';
  }

  @override
  String get reports => 'ሪፖርቶች';

  @override
  String reportsCountLabel(String count) {
    return '$count ሪፖርቶች';
  }

  @override
  String get generalService => 'አጠቃላይ አገልግሎት';

  @override
  String get publicService => 'የህዝብ አገልግሎት';

  @override
  String get viewDetails => 'ዝርዝር ይመልከቱ';

  @override
  String get noReportsYet => 'ምንም ሪፖርት የለም';

  @override
  String get noReportsSubtitle => 'የአገልግሎት ሪፖርቶችዎ እዚህ ይታያሉ።';

  @override
  String get noReportsYetEmergency => 'ምንም ሪፖርት የለም';

  @override
  String get noReportsSubtitleEmergency => 'የተላኩ ሪፖርቶችዎ እዚህ ይታያሉ።';

  @override
  String get failedToLoad => 'መጫን አልተሳካም';

  @override
  String get tryAgain => 'እንደገና ሞክር';

  @override
  String get profile => 'መገለጫ';

  @override
  String get profileLabel => 'መገለጫ';

  @override
  String get logout => 'ውጣ';

  @override
  String get logoutConfirmTitle => 'ውጣ';

  @override
  String get logoutConfirmMessage => 'እርግጠኛ ነዎት መውጣት ይፈልጋሉ?';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get editProfile => 'መገለጫ አርትዕ';

  @override
  String get verifyAccount => 'መለያ አረጋግጥ';

  @override
  String get personalInfo => 'የግል መረጃ';

  @override
  String get contactInfo => 'የእውቂያ መረጃ';

  @override
  String get accountInfo => 'የመለያ መረጃ';

  @override
  String get firstName => 'የመጀመሪያ ስም';

  @override
  String get lastName => 'የአባት ስም';

  @override
  String get dateOfBirth => 'የልደት ቀን';

  @override
  String get gender => 'ጾታ';

  @override
  String get email => 'ኢሜይል';

  @override
  String get phone => 'ስልክ';

  @override
  String get city => 'ከተማ';

  @override
  String get country => 'አገር';

  @override
  String get address => 'አድራሻ';

  @override
  String get accountType => 'የመለያ አይነት';

  @override
  String get memberSince => 'አባል የሆኑበት ቀን';

  @override
  String get failedToLoadProfile => 'መገለጫ መጫን አልተሳካም';

  @override
  String get retry => 'እንደገና ሞክር';

  @override
  String get uncategorized => 'ምድብ የለም';

  @override
  String get general => 'አጠቃላይ';

  @override
  String get recently => 'በቅርቡ';

  @override
  String get noDescription => 'መግለጫ አልተሰጠም።';

  @override
  String get notificationsLabel => 'ማሳወቂያዎች';

  @override
  String get switchToEnglish => 'ወደ እንግሊዘኛ ቀይር';

  @override
  String get switchToAmharic => 'ወደ አማርኛ ቀይር';

  @override
  String get defaultCaseType => 'ሪፖርት';

  @override
  String get reportPlaceholder => 'ሪፖርት';

  @override
  String emergencyCategoryLabel(String name) {
    return '$name';
  }

  @override
  String serviceCategoryLabel(String name) {
    return '$name';
  }

  @override
  String get caseTypesLabel => 'የጉዳይ አይነቶች';

  @override
  String get caseDetailLastKnownLocation => 'መጨረሻ የታወቀ አካባቢ';

  @override
  String get caseDetailPhysicalIdentifiers => 'አካላዊ መለያዎች';

  @override
  String get caseDetailDistinctiveMarks => 'ልዩ ምልክቶች';

  @override
  String get caseDetailCaseDescription => 'የጉዳዩ መግለጫ';

  @override
  String get caseDetailNoMarks => 'ምንም ልዩ ምልክቶች አልተዘገቡም።';

  @override
  String get caseDetailNoDescription => 'ተጨማሪ መግለጫ አልተሰጠም።';

  @override
  String get caseDetailUnknownIdentity => 'ማንነት አልታወቀም';

  @override
  String caseDetailLastSeen(String date) {
    return 'መጨረሻ የታየበት: $date';
  }

  @override
  String caseDetailAgeYrs(String age) {
    return '$age ዓ';
  }

  @override
  String get caseDetailAge => 'ዕድሜ';

  @override
  String get caseDetailGender => 'ጾታ';

  @override
  String get caseDetailHeight => 'ቁመት';

  @override
  String get caseDetailWeight => 'ክብደት';

  @override
  String get caseDetailLocationNotSet => 'አካባቢ አልተቀናበረም';

  @override
  String get caseDetailDangerAlert => 'አደጋ ማስጠንቀቂያ';

  @override
  String get caseDetailProvideTip => 'የማንነት ሳይገለጽ ፍንጭ ስጥ';

  @override
  String caseDetailEtb(String amount) {
    return '$amount ብር';
  }

  @override
  String get caseDetailStatusPending => 'በጥበቃ ላይ';

  @override
  String get caseDetailStatusInProgress => 'በሂደት ላይ';

  @override
  String get serviceReportDetails => 'የሪፖርት ዝርዝር';

  @override
  String get serviceStreetLabel => 'መንገድ';

  @override
  String get serviceDateReported => 'የተዘገበበት ቀን';

  @override
  String get serviceSystemStatus => 'የስርዓት ሁኔታ';

  @override
  String get serviceOfficialReport => 'ይፋዊ ሪፖርት';

  @override
  String get serviceReportLabel => 'የአገልግሎት ሪፖርት';

  @override
  String get openChat => 'ውይይት ክፈት';

  @override
  String get reportSectionDescription => 'መግለጫ';

  @override
  String get reportSectionLocation => 'የአካባቢ ዝርዝር';

  @override
  String get reportSectionTimeGps => 'ጊዜ እና ጂፒኤስ';

  @override
  String get reportSectionEvidence => 'ማስረጃ';

  @override
  String get reportDescriptionHint => 'ምን እየተፈጠረ እንደሆነ ያስረዱ...';

  @override
  String get reportSelectKebele => 'ቀበሌ ይምረጡ';

  @override
  String get reportSubdivisionHint => 'ክፍለ ከተማ';

  @override
  String get reportStreetHint => 'መንገድ (አማራጭ)';

  @override
  String get reportTimeLabel => 'የሪፖርት ጊዜ';

  @override
  String get reportSelectTime => 'ጊዜ ይምረጡ';

  @override
  String get reportPinLocation => 'አካባቢ ያስቀምጡ';

  @override
  String get reportTapToOpenMap => 'ካርታ ለመክፈት ይጫኑ';

  @override
  String get reportLocationPinned => 'አካባቢ ተቀምጧል';

  @override
  String get reportMediaAttachment => 'ሚዲያ አያያዥ';

  @override
  String get reportUploadPhotoVideo => 'ፎቶ/ቪዲዮ ይጫኑ';

  @override
  String get reportSubmitButton => 'ሪፖርት ያስገቡ';

  @override
  String get reportValidationError => 'መግለጫ ያስገቡ፣ ቀበሌ ይምረጡ፣ እና ክፍለ ከተማ ያስገቡ';

  @override
  String get reportFetchingUserId => 'የተጠቃሚ መለያ እየተጫነ ነው። እባክዎ ይጠብቁ...';

  @override
  String get reportErrorLoadingLocations => 'አካባቢዎችን መጫን አልተሳካም';

  @override
  String get reportFailedUserId => 'የተጠቃሚ መለያ ማግኘት አልተሳካም';

  @override
  String get reportSentSuccess => 'ሪፖርቱ በተሳካ ሁኔታ ተልኳል';

  @override
  String get reportSentFailed => 'ሪፖርቱን መላክ አልተሳካም';

  @override
  String get serviceRequestTitle => 'የአገልግሎት ጥያቄ';

  @override
  String get serviceSectionDescription => 'መግለጫ';

  @override
  String get serviceSectionLocation => 'የአካባቢ ዝርዝር';

  @override
  String get serviceSectionScheduleGps => 'ጊዜ እና ጂፒኤስ';

  @override
  String get serviceSectionEvidence => 'ማስረጃ / አባሪ';

  @override
  String get serviceDescriptionHint => 'የሚፈለገውን አገልግሎት ይግለጹ...';

  @override
  String get serviceSelectKebele => 'ቀበሌ ይምረጡ';

  @override
  String get serviceSubdivisionHint => 'ክፍለ ከተማ / ቀበሌ';

  @override
  String get serviceStreetHint => 'መንገድ (አማራጭ)';

  @override
  String get serviceRequestTimeLabel => 'የጥያቄ ጊዜ';

  @override
  String get serviceSetTime => 'ጊዜ ያስቀምጡ';

  @override
  String get serviceMarkLocation => 'አካባቢ ምልክት ያድርጉ';

  @override
  String get serviceOpenMap => 'ካርታ ክፈት';

  @override
  String get serviceLocationPinned => 'ተቀምጧል';

  @override
  String get serviceMediaLabel => 'ሚዲያ';

  @override
  String get serviceUploadMediaHint => 'ፎቶ/ቪዲዮ ይጫኑ';

  @override
  String get serviceSubmitButton => 'ጥያቄ ያስገቡ';

  @override
  String get serviceValidationError => 'መግለጫ ያስገቡ፣ ቀበሌ ይምረጡ፣ እና ክፍለ ከተማ ያስገቡ';

  @override
  String get serviceFetchingUserId => 'የተጠቃሚ መለያ እየተጫነ ነው። እባክዎ ይጠብቁ...';

  @override
  String get serviceErrorLoadingLocations => 'አካባቢዎችን መጫን አልተሳካም';

  @override
  String get serviceFailedUserId => 'የተጠቃሚ መለያ ማግኘት አልተሳካም';

  @override
  String get serviceRequestSentSuccess => 'የአገልግሎት ጥያቄ በተሳካ ሁኔታ ተልኳል';

  @override
  String get serviceRequestSentFailed => 'ጥያቄውን መላክ አልተሳካም';

  @override
  String get caseReportPageTitle => 'የስለላ ሪፖርት';

  @override
  String get caseReportPageSubtitle => 'ማየት ሪፖርት አቅርብ';

  @override
  String get caseReportSectionLocation => 'ጂኦግራፊያዊ ትክክለኛነት';

  @override
  String get caseReportSectionTime => 'የማየት ጊዜ';

  @override
  String get caseReportSelectDateTime => 'ቀን እና ጊዜ ይምረጡ';

  @override
  String get caseReportSectionDescription => 'የእይታ መግለጫ';

  @override
  String get caseReportDescriptionHint => 'ልብስ፣ አጃቢዎች፣ የተሽከርካሪ ዝርዝሮች...';

  @override
  String get caseReportSubmitButton => 'ሪፖርት ያስገቡ';

  @override
  String get caseReportEncryptedProtocol => 'የተመሰጠረ የአገልግሎት ፕሮቶኮል';

  @override
  String get caseReportReportingTarget => 'የሪፖርት ኢላማ';

  @override
  String get caseReportUnknownEntity => 'ያልታወቀ አካል';

  @override
  String get caseReportFetchLocationError => 'የአካባቢ ዳታ ማምጣት አልተሳካም';

  @override
  String get caseReportLocationTimeError => 'እባክዎ አካባቢ እና ጊዜ ይምረጡ';

  @override
  String get caseReportSentSuccess => 'ማየት በተሳካ ሁኔታ ቀርቧል';

  @override
  String get caseReportSentFailed => 'ማስገባት አልተሳካም። ግንኙነትዎን ያረጋግጡ።';

  @override
  String get homeDescription =>
      'የእርስዎ የህዝብ አገልግሎት እና የአደጋ ጊዜ ምላሽ መተግበሪያ — ባህር ዳርን ከአስተማማኝ እርዳታ ጋር ያገናኛል።';

  @override
  String get homeLetsStart => 'እንጀምር';

  @override
  String get homeAlreadyHaveAccount => 'መለያ አለዎት? ይግቡ';

  @override
  String get homeFeatureEmergency => 'አደጋ';

  @override
  String get homeFeatureServices => 'አገልግሎቶች';

  @override
  String get homeFeatureLiveReports => 'የቀጥታ ሪፖርቶች';

  @override
  String get loginWelcomeBack => 'እንኳን ደህና መጡ!';

  @override
  String get loginUsernameHint => 'የተጠቃሚ ስም';

  @override
  String get loginEnterUsername => 'የተጠቃሚ ስም ያስገቡ';

  @override
  String get loginPasswordHint => 'የይለፍ ቃል';

  @override
  String get loginPasswordTooShort => 'የይለፍ ቃሉ ያጠረ ነው';

  @override
  String get loginForgotPassword => 'የይለፍ ቃል ረሱ?';

  @override
  String get loginButton => 'ግባ';

  @override
  String get loginContinueAsGuest => 'እንደ እንግዳ ቀጥል';

  @override
  String get loginNewUser => 'አዲስ ተጠቃሚ? ';

  @override
  String get loginSignUp => 'ይመዝገቡ';

  @override
  String get signupCreateAccount => 'መለያ ፍጠር';

  @override
  String get signupFirstName => 'የመጀመሪያ ስም';

  @override
  String get signupEnterFirstName => 'የመጀመሪያ ስም ያስገቡ';

  @override
  String get signupLastName => 'የአባት ስም';

  @override
  String get signupEnterLastName => 'የአባት ስም ያስገቡ';

  @override
  String get signupEmailAddress => 'የኢሜይል አድራሻ';

  @override
  String get signupInvalidEmail => 'ልክ ያልሆነ ኢሜይል';

  @override
  String get signupPassword => 'የይለፍ ቃል';

  @override
  String get signupPasswordMin => 'ቢያንስ 6 ቁምፊዎች';

  @override
  String get signupCreateAccountButton => 'መለያ ፍጠር';

  @override
  String get signupAlreadyHaveAccount => 'መለያ አለዎት? ';

  @override
  String get signupLoginLink => 'ግባ';

  @override
  String get guestMode => 'የእንግዳ ሁኔታ';

  @override
  String get guestUser => 'የእንግዳ ተጠቃሚ';

  @override
  String get guestFreeToJoin => 'ለመቀላቀል ነፃ ነው';

  @override
  String get guestUnlockTitle => 'ሙሉ መዳረሻ ያግኙ';

  @override
  String get guestUnlockSubtitle =>
      'ነፃ መለያ ፍጠሩ — አደጋዎችን ሪፖርት ያድርጉ፣ ጉዳዮችዎን ይከታተሉ፣ ሽልማቶችን ያግኙ እና በባህር ዳር የቀጥታ ማሳወቂያዎችን ይቀበሉ።';

  @override
  String get guestFeatureReport => 'አደጋ ሪፖርት ያድርጉ';

  @override
  String get guestFeatureTrack => 'ጉዳዮችን ይከታተሉ';

  @override
  String get guestFeatureRewards => 'ሽልማቶችን ያግኙ';

  @override
  String get guestFeatureAlerts => 'የቀጥታ ማሳወቂያዎች';

  @override
  String get guestSignInCta => 'ነፃ መለያ ፍጠሩ';

  @override
  String get guestContactSection => 'የእውቂያ መረጃ';

  @override
  String get guestContactPhone => 'የእውቂያ ስልክ ቁጥር';

  @override
  String get navHome => 'ዋና ገጽ';

  @override
  String get navServices => 'አገልግሎቶች';

  @override
  String get navProfile => 'መገለጫ';

  @override
  String get navReports => 'ሪፖርቶች';

  @override
  String get navSettings => 'ቅንብሮች';

  @override
  String rdReportedAt(String time) {
    return 'የተዘገበበት ሰዓት $time';
  }

  @override
  String get rdSectionDescription => 'መግለጫ';

  @override
  String get rdSectionLocation => 'አካባቢ';

  @override
  String get rdLocationSubtitle => 'ባህር ዳር · ቀበሌ';

  @override
  String get rdEmergencyReport => 'የአደጋ ሪፖርት';

  @override
  String get rdUpdateDetails => 'ዝርዝር አዘምን';

  @override
  String get rdArchiveTitle => 'ሪፖርቱን ማህደር አድርግ?';

  @override
  String get rdArchiveMessage => 'ይህ ሪፖርት ከአሁኑ እይታዎ ይደበቃል።';

  @override
  String get rdKeep => 'አቆይ';

  @override
  String get rdArchive => 'ማህደር አድርግ';

  @override
  String get rdUpdateReport => 'ሪፖርት አዘምን';

  @override
  String get rdFieldKebele => 'ቀበሌ';

  @override
  String get rdFieldDescription => 'መግለጫ';

  @override
  String get rdDiscard => 'ተው';

  @override
  String get rdSaveChanges => 'ለውጦችን አስቀምጥ';
}
