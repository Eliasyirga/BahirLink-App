// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BahirLink';

  @override
  String get tagline => 'Your city. Connected.';

  @override
  String get goodMorning => 'Good morning 👋';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get locationCity => 'Bahir Dar';

  @override
  String get liveReports => 'Live Reports';

  @override
  String activeBadge(String count) {
    return '$count Active';
  }

  @override
  String get emergencyAssist => 'Emergency Assist';

  @override
  String get publicServices => 'Public Services';

  @override
  String get seeAll => 'See all';

  @override
  String get incidentReported => 'Incident Reported';

  @override
  String rewardLabel(String amount) {
    return '$amount ETB';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get myPublic => 'My Public';

  @override
  String get serviceReports => 'Service Reports';

  @override
  String reportsCount(String count) {
    return '$count Reports';
  }

  @override
  String get generalService => 'General Service';

  @override
  String get publicService => 'Public Service';

  @override
  String get statusCompleted => 'COMPLETED';

  @override
  String get statusRejected => 'REJECTED';

  @override
  String get viewDetails => 'View details';

  @override
  String get noReportsYet => 'No Reports Yet';

  @override
  String get noReportsSubtitle => 'Your service reports will appear here.';

  @override
  String get failedToLoad => 'Failed to Load';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get verifyAccount => 'Verify Account';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get contactInfo => 'Contact Info';

  @override
  String get accountInfo => 'Account Info';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get gender => 'Gender';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get city => 'City';

  @override
  String get country => 'Country';

  @override
  String get address => 'Address';

  @override
  String get accountType => 'Account Type';

  @override
  String get memberSince => 'Member Since';

  @override
  String get statusActive => 'Active';

  @override
  String get failedToLoadProfile => 'Failed to load profile';

  @override
  String get retry => 'Retry';

  @override
  String get myEmergency => 'My Emergency';

  @override
  String get reports => 'Reports';

  @override
  String reportsCountLabel(String count) {
    return '$count Reports';
  }

  @override
  String get noReportsYetEmergency => 'No Reports Yet';

  @override
  String get noReportsSubtitleEmergency =>
      'Your submitted reports will appear here.';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get general => 'General';

  @override
  String get recently => 'Recently';

  @override
  String get noDescription => 'No description provided.';
}
