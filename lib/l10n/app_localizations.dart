import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

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
    Locale('am'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BahirLink'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your city. Connected.'**
  String get tagline;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning 👋'**
  String get goodMorning;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @locationCity.
  ///
  /// In en, this message translates to:
  /// **'Bahir Dar'**
  String get locationCity;

  /// No description provided for @liveReports.
  ///
  /// In en, this message translates to:
  /// **'Live Reports'**
  String get liveReports;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} Active'**
  String activeBadge(String count);

  /// No description provided for @emergencyAssist.
  ///
  /// In en, this message translates to:
  /// **'Emergency Assist'**
  String get emergencyAssist;

  /// No description provided for @publicServices.
  ///
  /// In en, this message translates to:
  /// **'Public Services'**
  String get publicServices;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @incidentReported.
  ///
  /// In en, this message translates to:
  /// **'Incident Reported'**
  String get incidentReported;

  /// No description provided for @rewardLabel.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB'**
  String rewardLabel(String amount);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get statusCompleted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get statusRejected;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @myPublic.
  ///
  /// In en, this message translates to:
  /// **'My Public'**
  String get myPublic;

  /// No description provided for @myEmergency.
  ///
  /// In en, this message translates to:
  /// **'My Emergency'**
  String get myEmergency;

  /// No description provided for @serviceReports.
  ///
  /// In en, this message translates to:
  /// **'Service Reports'**
  String get serviceReports;

  /// No description provided for @reportsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Reports'**
  String reportsCount(String count);

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @reportsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Reports'**
  String reportsCountLabel(String count);

  /// No description provided for @generalService.
  ///
  /// In en, this message translates to:
  /// **'General Service'**
  String get generalService;

  /// No description provided for @publicService.
  ///
  /// In en, this message translates to:
  /// **'Public Service'**
  String get publicService;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No Reports Yet'**
  String get noReportsYet;

  /// No description provided for @noReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your service reports will appear here.'**
  String get noReportsSubtitle;

  /// No description provided for @noReportsYetEmergency.
  ///
  /// In en, this message translates to:
  /// **'No Reports Yet'**
  String get noReportsYetEmergency;

  /// No description provided for @noReportsSubtitleEmergency.
  ///
  /// In en, this message translates to:
  /// **'Your submitted reports will appear here.'**
  String get noReportsSubtitleEmergency;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load'**
  String get failedToLoad;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @verifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify Account'**
  String get verifyAccount;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfo;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get accountInfo;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @recently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recently;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescription;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @switchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Switch to English'**
  String get switchToEnglish;

  /// No description provided for @switchToAmharic.
  ///
  /// In en, this message translates to:
  /// **'Switch to Amharic'**
  String get switchToAmharic;

  /// No description provided for @defaultCaseType.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get defaultCaseType;

  /// No description provided for @reportPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportPlaceholder;

  /// No description provided for @emergencyCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String emergencyCategoryLabel(String name);

  /// No description provided for @serviceCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String serviceCategoryLabel(String name);

  /// No description provided for @caseTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'Case Types'**
  String get caseTypesLabel;

  /// No description provided for @caseDetailLastKnownLocation.
  ///
  /// In en, this message translates to:
  /// **'Last Known Location'**
  String get caseDetailLastKnownLocation;

  /// No description provided for @caseDetailPhysicalIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'Physical Identifiers'**
  String get caseDetailPhysicalIdentifiers;

  /// No description provided for @caseDetailDistinctiveMarks.
  ///
  /// In en, this message translates to:
  /// **'Distinctive Marks'**
  String get caseDetailDistinctiveMarks;

  /// No description provided for @caseDetailCaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Case Description'**
  String get caseDetailCaseDescription;

  /// No description provided for @caseDetailNoMarks.
  ///
  /// In en, this message translates to:
  /// **'No distinctive marks reported.'**
  String get caseDetailNoMarks;

  /// No description provided for @caseDetailNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No additional description provided.'**
  String get caseDetailNoDescription;

  /// No description provided for @caseDetailUnknownIdentity.
  ///
  /// In en, this message translates to:
  /// **'Unknown Identity'**
  String get caseDetailUnknownIdentity;

  /// No description provided for @caseDetailLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen: {date}'**
  String caseDetailLastSeen(String date);

  /// No description provided for @caseDetailAgeYrs.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs'**
  String caseDetailAgeYrs(String age);

  /// No description provided for @caseDetailAge.
  ///
  /// In en, this message translates to:
  /// **'AGE'**
  String get caseDetailAge;

  /// No description provided for @caseDetailGender.
  ///
  /// In en, this message translates to:
  /// **'GENDER'**
  String get caseDetailGender;

  /// No description provided for @caseDetailHeight.
  ///
  /// In en, this message translates to:
  /// **'HEIGHT'**
  String get caseDetailHeight;

  /// No description provided for @caseDetailWeight.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get caseDetailWeight;

  /// No description provided for @caseDetailLocationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location Not Set'**
  String get caseDetailLocationNotSet;

  /// No description provided for @caseDetailDangerAlert.
  ///
  /// In en, this message translates to:
  /// **'DANGER ALERT'**
  String get caseDetailDangerAlert;

  /// No description provided for @caseDetailProvideTip.
  ///
  /// In en, this message translates to:
  /// **'PROVIDE ANONYMOUS TIP'**
  String get caseDetailProvideTip;

  /// No description provided for @caseDetailEtb.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB'**
  String caseDetailEtb(String amount);

  /// No description provided for @caseDetailStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get caseDetailStatusPending;

  /// No description provided for @caseDetailStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get caseDetailStatusInProgress;

  /// No description provided for @serviceReportDetails.
  ///
  /// In en, this message translates to:
  /// **'REPORT DETAILS'**
  String get serviceReportDetails;

  /// No description provided for @serviceStreetLabel.
  ///
  /// In en, this message translates to:
  /// **'STREET'**
  String get serviceStreetLabel;

  /// No description provided for @serviceDateReported.
  ///
  /// In en, this message translates to:
  /// **'DATE REPORTED'**
  String get serviceDateReported;

  /// No description provided for @serviceSystemStatus.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM STATUS'**
  String get serviceSystemStatus;

  /// No description provided for @serviceOfficialReport.
  ///
  /// In en, this message translates to:
  /// **'Official Report'**
  String get serviceOfficialReport;

  /// No description provided for @serviceReportLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Report'**
  String get serviceReportLabel;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get openChat;

  /// No description provided for @reportSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reportSectionDescription;

  /// No description provided for @reportSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get reportSectionLocation;

  /// No description provided for @reportSectionTimeGps.
  ///
  /// In en, this message translates to:
  /// **'Time & GPS'**
  String get reportSectionTimeGps;

  /// No description provided for @reportSectionEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get reportSectionEvidence;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Explain what is happening...'**
  String get reportDescriptionHint;

  /// No description provided for @reportSelectKebele.
  ///
  /// In en, this message translates to:
  /// **'Select Kebele'**
  String get reportSelectKebele;

  /// No description provided for @reportSubdivisionHint.
  ///
  /// In en, this message translates to:
  /// **'Subdivision'**
  String get reportSubdivisionHint;

  /// No description provided for @reportStreetHint.
  ///
  /// In en, this message translates to:
  /// **'Street (Optional)'**
  String get reportStreetHint;

  /// No description provided for @reportTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Report Time'**
  String get reportTimeLabel;

  /// No description provided for @reportSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get reportSelectTime;

  /// No description provided for @reportPinLocation.
  ///
  /// In en, this message translates to:
  /// **'Pin Location'**
  String get reportPinLocation;

  /// No description provided for @reportTapToOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to open map'**
  String get reportTapToOpenMap;

  /// No description provided for @reportLocationPinned.
  ///
  /// In en, this message translates to:
  /// **'Location Pinned'**
  String get reportLocationPinned;

  /// No description provided for @reportMediaAttachment.
  ///
  /// In en, this message translates to:
  /// **'Media Attachment'**
  String get reportMediaAttachment;

  /// No description provided for @reportUploadPhotoVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo/Video'**
  String get reportUploadPhotoVideo;

  /// No description provided for @reportSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT REPORT'**
  String get reportSubmitButton;

  /// No description provided for @reportValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please fill description, select a kebele, and subdivision'**
  String get reportValidationError;

  /// No description provided for @reportFetchingUserId.
  ///
  /// In en, this message translates to:
  /// **'Fetching user ID. Please wait...'**
  String get reportFetchingUserId;

  /// No description provided for @reportErrorLoadingLocations.
  ///
  /// In en, this message translates to:
  /// **'Error loading locations'**
  String get reportErrorLoadingLocations;

  /// No description provided for @reportFailedUserId.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch user ID'**
  String get reportFailedUserId;

  /// No description provided for @reportSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report Sent Successfully'**
  String get reportSentSuccess;

  /// No description provided for @reportSentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to Send Report'**
  String get reportSentFailed;

  /// No description provided for @serviceRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Request'**
  String get serviceRequestTitle;

  /// No description provided for @serviceSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get serviceSectionDescription;

  /// No description provided for @serviceSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get serviceSectionLocation;

  /// No description provided for @serviceSectionScheduleGps.
  ///
  /// In en, this message translates to:
  /// **'Schedule & GPS'**
  String get serviceSectionScheduleGps;

  /// No description provided for @serviceSectionEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence / Attachment'**
  String get serviceSectionEvidence;

  /// No description provided for @serviceDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the required service...'**
  String get serviceDescriptionHint;

  /// No description provided for @serviceSelectKebele.
  ///
  /// In en, this message translates to:
  /// **'Select Kebele'**
  String get serviceSelectKebele;

  /// No description provided for @serviceSubdivisionHint.
  ///
  /// In en, this message translates to:
  /// **'Subdivision / Village'**
  String get serviceSubdivisionHint;

  /// No description provided for @serviceStreetHint.
  ///
  /// In en, this message translates to:
  /// **'Street (Optional)'**
  String get serviceStreetHint;

  /// No description provided for @serviceRequestTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Request Time'**
  String get serviceRequestTimeLabel;

  /// No description provided for @serviceSetTime.
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get serviceSetTime;

  /// No description provided for @serviceMarkLocation.
  ///
  /// In en, this message translates to:
  /// **'Mark Location'**
  String get serviceMarkLocation;

  /// No description provided for @serviceOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get serviceOpenMap;

  /// No description provided for @serviceLocationPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get serviceLocationPinned;

  /// No description provided for @serviceMediaLabel.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get serviceMediaLabel;

  /// No description provided for @serviceUploadMediaHint.
  ///
  /// In en, this message translates to:
  /// **'Upload Image/Video'**
  String get serviceUploadMediaHint;

  /// No description provided for @serviceSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT REQUEST'**
  String get serviceSubmitButton;

  /// No description provided for @serviceValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please fill description, select a kebele, and subdivision'**
  String get serviceValidationError;

  /// No description provided for @serviceFetchingUserId.
  ///
  /// In en, this message translates to:
  /// **'Fetching user ID. Please wait...'**
  String get serviceFetchingUserId;

  /// No description provided for @serviceErrorLoadingLocations.
  ///
  /// In en, this message translates to:
  /// **'Error loading locations'**
  String get serviceErrorLoadingLocations;

  /// No description provided for @serviceFailedUserId.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch user ID'**
  String get serviceFailedUserId;

  /// No description provided for @serviceRequestSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service Request Sent Successfully'**
  String get serviceRequestSentSuccess;

  /// No description provided for @serviceRequestSentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to Send Request'**
  String get serviceRequestSentFailed;

  /// No description provided for @caseReportPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Intel Report'**
  String get caseReportPageTitle;

  /// No description provided for @caseReportPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit a sighting'**
  String get caseReportPageSubtitle;

  /// No description provided for @caseReportSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Geographic Precision'**
  String get caseReportSectionLocation;

  /// No description provided for @caseReportSectionTime.
  ///
  /// In en, this message translates to:
  /// **'Time of Sighting'**
  String get caseReportSectionTime;

  /// No description provided for @caseReportSelectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select date & time'**
  String get caseReportSelectDateTime;

  /// No description provided for @caseReportSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Visual Description'**
  String get caseReportSectionDescription;

  /// No description provided for @caseReportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Clothing, companions, vehicle details...'**
  String get caseReportDescriptionHint;

  /// No description provided for @caseReportSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get caseReportSubmitButton;

  /// No description provided for @caseReportEncryptedProtocol.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Service Protocol'**
  String get caseReportEncryptedProtocol;

  /// No description provided for @caseReportReportingTarget.
  ///
  /// In en, this message translates to:
  /// **'Reporting Target'**
  String get caseReportReportingTarget;

  /// No description provided for @caseReportUnknownEntity.
  ///
  /// In en, this message translates to:
  /// **'Unknown Entity'**
  String get caseReportUnknownEntity;

  /// No description provided for @caseReportFetchLocationError.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch location data'**
  String get caseReportFetchLocationError;

  /// No description provided for @caseReportLocationTimeError.
  ///
  /// In en, this message translates to:
  /// **'Please select both location and time'**
  String get caseReportLocationTimeError;

  /// No description provided for @caseReportSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sighting submitted successfully'**
  String get caseReportSentSuccess;

  /// No description provided for @caseReportSentFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed. Please check connection.'**
  String get caseReportSentFailed;

  /// No description provided for @homeDescription.
  ///
  /// In en, this message translates to:
  /// **'Your trusted public service & emergency response app — connecting Bahir Dar with reliable assistance.'**
  String get homeDescription;

  /// No description provided for @homeLetsStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Start'**
  String get homeLetsStart;

  /// No description provided for @homeAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get homeAlreadyHaveAccount;

  /// No description provided for @homeFeatureEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get homeFeatureEmergency;

  /// No description provided for @homeFeatureServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get homeFeatureServices;

  /// No description provided for @homeFeatureLiveReports.
  ///
  /// In en, this message translates to:
  /// **'Live Reports'**
  String get homeFeatureLiveReports;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginWelcomeBack;

  /// No description provided for @loginUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsernameHint;

  /// No description provided for @loginEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get loginEnterUsername;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short'**
  String get loginPasswordTooShort;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get loginContinueAsGuest;

  /// No description provided for @loginNewUser.
  ///
  /// In en, this message translates to:
  /// **'New user? '**
  String get loginNewUser;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// No description provided for @signupCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupCreateAccount;

  /// No description provided for @signupFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get signupFirstName;

  /// No description provided for @signupEnterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get signupEnterFirstName;

  /// No description provided for @signupLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get signupLastName;

  /// No description provided for @signupEnterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get signupEnterLastName;

  /// No description provided for @signupEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get signupEmailAddress;

  /// No description provided for @signupInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get signupInvalidEmail;

  /// No description provided for @signupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPassword;

  /// No description provided for @signupPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get signupPasswordMin;

  /// No description provided for @signupCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupCreateAccountButton;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get signupLoginLink;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guestMode;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @guestFreeToJoin.
  ///
  /// In en, this message translates to:
  /// **'Free to Join'**
  String get guestFreeToJoin;

  /// No description provided for @guestUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Full Access'**
  String get guestUnlockTitle;

  /// No description provided for @guestUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to report incidents, track your cases, earn rewards, and receive real-time alerts in Bahir Dar.'**
  String get guestUnlockSubtitle;

  /// No description provided for @guestFeatureReport.
  ///
  /// In en, this message translates to:
  /// **'Report Incidents'**
  String get guestFeatureReport;

  /// No description provided for @guestFeatureTrack.
  ///
  /// In en, this message translates to:
  /// **'Track Cases'**
  String get guestFeatureTrack;

  /// No description provided for @guestFeatureRewards.
  ///
  /// In en, this message translates to:
  /// **'Earn Rewards'**
  String get guestFeatureRewards;

  /// No description provided for @guestFeatureAlerts.
  ///
  /// In en, this message translates to:
  /// **'Live Alerts'**
  String get guestFeatureAlerts;

  /// No description provided for @guestSignInCta.
  ///
  /// In en, this message translates to:
  /// **'Create Free Account'**
  String get guestSignInCta;

  /// No description provided for @guestContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get guestContactSection;

  /// No description provided for @guestContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone Number'**
  String get guestContactPhone;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navServices;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @rdReportedAt.
  ///
  /// In en, this message translates to:
  /// **'Reported at {time}'**
  String rdReportedAt(String time);

  /// No description provided for @rdSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get rdSectionDescription;

  /// No description provided for @rdSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get rdSectionLocation;

  /// No description provided for @rdLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'BAHIR DAR · KEBELE'**
  String get rdLocationSubtitle;

  /// No description provided for @rdEmergencyReport.
  ///
  /// In en, this message translates to:
  /// **'Emergency Report'**
  String get rdEmergencyReport;

  /// No description provided for @rdUpdateDetails.
  ///
  /// In en, this message translates to:
  /// **'Update Details'**
  String get rdUpdateDetails;

  /// No description provided for @rdArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Report?'**
  String get rdArchiveTitle;

  /// No description provided for @rdArchiveMessage.
  ///
  /// In en, this message translates to:
  /// **'This report will be hidden from your current view.'**
  String get rdArchiveMessage;

  /// No description provided for @rdKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get rdKeep;

  /// No description provided for @rdArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get rdArchive;

  /// No description provided for @rdUpdateReport.
  ///
  /// In en, this message translates to:
  /// **'Update Report'**
  String get rdUpdateReport;

  /// No description provided for @rdFieldKebele.
  ///
  /// In en, this message translates to:
  /// **'Kebele'**
  String get rdFieldKebele;

  /// No description provided for @rdFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get rdFieldDescription;

  /// No description provided for @rdDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get rdDiscard;

  /// No description provided for @rdSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get rdSaveChanges;
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
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
