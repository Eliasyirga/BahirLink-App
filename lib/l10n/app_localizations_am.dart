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
  String get myPublic => 'የእኔ';

  @override
  String get serviceReports => 'የአገልግሎት ሪፖርቶች';

  @override
  String reportsCount(String count) {
    return '$count ሪፖርቶች';
  }

  @override
  String get generalService => 'አጠቃላይ አገልግሎት';

  @override
  String get publicService => 'የህዝብ አገልግሎት';

  @override
  String get statusCompleted => 'ተጠናቋል';

  @override
  String get statusRejected => 'ተቀባይነት አላገኘም';

  @override
  String get viewDetails => 'ዝርዝር ይመልከቱ';

  @override
  String get noReportsYet => 'ምንም ሪፖርት የለም';

  @override
  String get noReportsSubtitle => 'የአገልግሎት ሪፖርቶችዎ እዚህ ይታያሉ።';

  @override
  String get failedToLoad => 'መጫን አልተሳካም';

  @override
  String get tryAgain => 'እንደገና ሞክር';

  @override
  String get profile => 'መገለጫ';

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
  String get statusActive => 'ንቁ';

  @override
  String get failedToLoadProfile => 'መገለጫ መጫን አልተሳካም';

  @override
  String get retry => 'እንደገና ሞክር';

  @override
  String get myEmergency => 'የእኔ አደጋ';

  @override
  String get reports => 'ሪፖርቶች';

  @override
  String reportsCountLabel(String count) {
    return '$count ሪፖርቶች';
  }

  @override
  String get noReportsYetEmergency => 'ምንም ሪፖርት የለም';

  @override
  String get noReportsSubtitleEmergency => 'የተላኩ ሪፖርቶችዎ እዚህ ይታያሉ።';

  @override
  String get uncategorized => 'ምድብ የለም';

  @override
  String get general => 'አጠቃላይ';

  @override
  String get recently => 'በቅርቡ';

  @override
  String get noDescription => 'መግለጫ አልተሰጠም።';
}
