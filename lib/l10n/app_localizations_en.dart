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
  String get statusCompleted => 'COMPLETED';

  @override
  String get statusRejected => 'REJECTED';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get statusActive => 'Active';

  @override
  String get myPublic => 'My Public';

  @override
  String get myEmergency => 'My Emergency';

  @override
  String get serviceReports => 'Service Reports';

  @override
  String reportsCount(String count) {
    return '$count Reports';
  }

  @override
  String get reports => 'Reports';

  @override
  String reportsCountLabel(String count) {
    return '$count Reports';
  }

  @override
  String get generalService => 'General Service';

  @override
  String get publicService => 'Public Service';

  @override
  String get viewDetails => 'View details';

  @override
  String get noReportsYet => 'No Reports Yet';

  @override
  String get noReportsSubtitle => 'Your service reports will appear here.';

  @override
  String get noReportsYetEmergency => 'No Reports Yet';

  @override
  String get noReportsSubtitleEmergency =>
      'Your submitted reports will appear here.';

  @override
  String get failedToLoad => 'Failed to Load';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get profile => 'Profile';

  @override
  String get profileLabel => 'Profile';

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
  String get failedToLoadProfile => 'Failed to load profile';

  @override
  String get retry => 'Retry';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get general => 'General';

  @override
  String get recently => 'Recently';

  @override
  String get noDescription => 'No description provided.';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get switchToEnglish => 'Switch to English';

  @override
  String get switchToAmharic => 'Switch to Amharic';

  @override
  String get defaultCaseType => 'Report';

  @override
  String get reportPlaceholder => 'Report';

  @override
  String emergencyCategoryLabel(String name) {
    return '$name';
  }

  @override
  String serviceCategoryLabel(String name) {
    return '$name';
  }

  @override
  String get caseTypesLabel => 'Case Types';

  @override
  String get caseDetailLastKnownLocation => 'Last Known Location';

  @override
  String get caseDetailPhysicalIdentifiers => 'Physical Identifiers';

  @override
  String get caseDetailDistinctiveMarks => 'Distinctive Marks';

  @override
  String get caseDetailCaseDescription => 'Case Description';

  @override
  String get caseDetailNoMarks => 'No distinctive marks reported.';

  @override
  String get caseDetailNoDescription => 'No additional description provided.';

  @override
  String get caseDetailUnknownIdentity => 'Unknown Identity';

  @override
  String caseDetailLastSeen(String date) {
    return 'Last seen: $date';
  }

  @override
  String caseDetailAgeYrs(String age) {
    return '$age yrs';
  }

  @override
  String get caseDetailAge => 'AGE';

  @override
  String get caseDetailGender => 'GENDER';

  @override
  String get caseDetailHeight => 'HEIGHT';

  @override
  String get caseDetailWeight => 'WEIGHT';

  @override
  String get caseDetailLocationNotSet => 'Location Not Set';

  @override
  String get caseDetailDangerAlert => 'DANGER ALERT';

  @override
  String get caseDetailProvideTip => 'PROVIDE ANONYMOUS TIP';

  @override
  String caseDetailEtb(String amount) {
    return '$amount ETB';
  }

  @override
  String get caseDetailStatusPending => 'Pending';

  @override
  String get caseDetailStatusInProgress => 'In Progress';

  @override
  String get serviceReportDetails => 'REPORT DETAILS';

  @override
  String get serviceStreetLabel => 'STREET';

  @override
  String get serviceDateReported => 'DATE REPORTED';

  @override
  String get serviceSystemStatus => 'SYSTEM STATUS';

  @override
  String get serviceOfficialReport => 'Official Report';

  @override
  String get serviceReportLabel => 'Service Report';

  @override
  String get openChat => 'Open Chat';

  @override
  String get reportSectionDescription => 'Description';

  @override
  String get reportSectionLocation => 'Location Details';

  @override
  String get reportSectionTimeGps => 'Time & GPS';

  @override
  String get reportSectionEvidence => 'Evidence';

  @override
  String get reportDescriptionHint => 'Explain what is happening...';

  @override
  String get reportSelectKebele => 'Select Kebele';

  @override
  String get reportSubdivisionHint => 'Subdivision';

  @override
  String get reportStreetHint => 'Street (Optional)';

  @override
  String get reportTimeLabel => 'Report Time';

  @override
  String get reportSelectTime => 'Select Time';

  @override
  String get reportPinLocation => 'Pin Location';

  @override
  String get reportTapToOpenMap => 'Tap to open map';

  @override
  String get reportLocationPinned => 'Location Pinned';

  @override
  String get reportMediaAttachment => 'Media Attachment';

  @override
  String get reportUploadPhotoVideo => 'Upload Photo/Video';

  @override
  String get reportSubmitButton => 'SUBMIT REPORT';

  @override
  String get reportValidationError =>
      'Please fill description, select a kebele, and subdivision';

  @override
  String get reportFetchingUserId => 'Fetching user ID. Please wait...';

  @override
  String get reportErrorLoadingLocations => 'Error loading locations';

  @override
  String get reportFailedUserId => 'Failed to fetch user ID';

  @override
  String get reportSentSuccess => 'Report Sent Successfully';

  @override
  String get reportSentFailed => 'Failed to Send Report';

  @override
  String get serviceRequestTitle => 'Service Request';

  @override
  String get serviceSectionDescription => 'Description';

  @override
  String get serviceSectionLocation => 'Location Details';

  @override
  String get serviceSectionScheduleGps => 'Schedule & GPS';

  @override
  String get serviceSectionEvidence => 'Evidence / Attachment';

  @override
  String get serviceDescriptionHint => 'Describe the required service...';

  @override
  String get serviceSelectKebele => 'Select Kebele';

  @override
  String get serviceSubdivisionHint => 'Subdivision / Village';

  @override
  String get serviceStreetHint => 'Street (Optional)';

  @override
  String get serviceRequestTimeLabel => 'Request Time';

  @override
  String get serviceSetTime => 'Set Time';

  @override
  String get serviceMarkLocation => 'Mark Location';

  @override
  String get serviceOpenMap => 'Open Map';

  @override
  String get serviceLocationPinned => 'Pinned';

  @override
  String get serviceMediaLabel => 'Media';

  @override
  String get serviceUploadMediaHint => 'Upload Image/Video';

  @override
  String get serviceSubmitButton => 'SUBMIT REQUEST';

  @override
  String get serviceValidationError =>
      'Please fill description, select a kebele, and subdivision';

  @override
  String get serviceFetchingUserId => 'Fetching user ID. Please wait...';

  @override
  String get serviceErrorLoadingLocations => 'Error loading locations';

  @override
  String get serviceFailedUserId => 'Failed to fetch user ID';

  @override
  String get serviceRequestSentSuccess => 'Service Request Sent Successfully';

  @override
  String get serviceRequestSentFailed => 'Failed to Send Request';

  @override
  String get caseReportPageTitle => 'Intel Report';

  @override
  String get caseReportPageSubtitle => 'Submit a sighting';

  @override
  String get caseReportSectionLocation => 'Geographic Precision';

  @override
  String get caseReportSectionTime => 'Time of Sighting';

  @override
  String get caseReportSelectDateTime => 'Select date & time';

  @override
  String get caseReportSectionDescription => 'Visual Description';

  @override
  String get caseReportDescriptionHint =>
      'Clothing, companions, vehicle details...';

  @override
  String get caseReportSubmitButton => 'Submit Report';

  @override
  String get caseReportEncryptedProtocol => 'Encrypted Service Protocol';

  @override
  String get caseReportReportingTarget => 'Reporting Target';

  @override
  String get caseReportUnknownEntity => 'Unknown Entity';

  @override
  String get caseReportFetchLocationError => 'Failed to fetch location data';

  @override
  String get caseReportLocationTimeError =>
      'Please select both location and time';

  @override
  String get caseReportSentSuccess => 'Sighting submitted successfully';

  @override
  String get caseReportSentFailed =>
      'Submission failed. Please check connection.';

  @override
  String get homeDescription =>
      'Your trusted public service & emergency response app — connecting Bahir Dar with reliable assistance.';

  @override
  String get homeLetsStart => 'Let\'s Start';

  @override
  String get homeAlreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get homeFeatureEmergency => 'Emergency';

  @override
  String get homeFeatureServices => 'Services';

  @override
  String get homeFeatureLiveReports => 'Live Reports';

  @override
  String get loginWelcomeBack => 'Welcome back!';

  @override
  String get loginUsernameHint => 'Username';

  @override
  String get loginEnterUsername => 'Enter username';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginPasswordTooShort => 'Password too short';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Login';

  @override
  String get loginContinueAsGuest => 'Continue as Guest';

  @override
  String get loginNewUser => 'New user? ';

  @override
  String get loginSignUp => 'Sign Up';

  @override
  String get signupCreateAccount => 'Create Account';

  @override
  String get signupFirstName => 'First Name';

  @override
  String get signupEnterFirstName => 'Enter first name';

  @override
  String get signupLastName => 'Last Name';

  @override
  String get signupEnterLastName => 'Enter last name';

  @override
  String get signupEmailAddress => 'Email Address';

  @override
  String get signupInvalidEmail => 'Invalid email';

  @override
  String get signupPassword => 'Password';

  @override
  String get signupPasswordMin => 'Min 6 characters';

  @override
  String get signupCreateAccountButton => 'Create Account';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get signupLoginLink => 'Login';

  @override
  String get guestMode => 'Guest Mode';

  @override
  String get guestUser => 'Guest User';

  @override
  String get guestFreeToJoin => 'Free to Join';

  @override
  String get guestUnlockTitle => 'Unlock Full Access';

  @override
  String get guestUnlockSubtitle =>
      'Create a free account to report incidents, track your cases, earn rewards, and receive real-time alerts in Bahir Dar.';

  @override
  String get guestFeatureReport => 'Report Incidents';

  @override
  String get guestFeatureTrack => 'Track Cases';

  @override
  String get guestFeatureRewards => 'Earn Rewards';

  @override
  String get guestFeatureAlerts => 'Live Alerts';

  @override
  String get guestSignInCta => 'Create Free Account';

  @override
  String get guestContactSection => 'Contact Info';

  @override
  String get guestContactPhone => 'Contact Phone Number';

  @override
  String get navHome => 'Home';

  @override
  String get navServices => 'Services';

  @override
  String get navProfile => 'Profile';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String rdReportedAt(String time) {
    return 'Reported at $time';
  }

  @override
  String get rdSectionDescription => 'DESCRIPTION';

  @override
  String get rdSectionLocation => 'LOCATION';

  @override
  String get rdLocationSubtitle => 'BAHIR DAR · KEBELE';

  @override
  String get rdEmergencyReport => 'Emergency Report';

  @override
  String get rdUpdateDetails => 'Update Details';

  @override
  String get rdArchiveTitle => 'Archive Report?';

  @override
  String get rdArchiveMessage =>
      'This report will be hidden from your current view.';

  @override
  String get rdKeep => 'Keep';

  @override
  String get rdArchive => 'Archive';

  @override
  String get rdUpdateReport => 'Update Report';

  @override
  String get rdFieldKebele => 'Kebele';

  @override
  String get rdFieldDescription => 'Description';

  @override
  String get rdDiscard => 'Discard';

  @override
  String get rdSaveChanges => 'Save Changes';
}
