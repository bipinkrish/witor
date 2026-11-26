import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('hi'),
  ];

  /// No description provided for @wiFiCheck.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi check'**
  String get wiFiCheck;

  /// No description provided for @connectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Connection details'**
  String get connectionDetails;

  /// No description provided for @networkType.
  ///
  /// In en, this message translates to:
  /// **'Network type'**
  String get networkType;

  /// No description provided for @lastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked'**
  String get lastChecked;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get checkConnection;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @notCheckedYet.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get notCheckedYet;

  /// No description provided for @checkReport.
  ///
  /// In en, this message translates to:
  /// **'Check report'**
  String get checkReport;

  /// No description provided for @checkSettings.
  ///
  /// In en, this message translates to:
  /// **'Check settings'**
  String get checkSettings;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @aboutWitor.
  ///
  /// In en, this message translates to:
  /// **'About witor'**
  String get aboutWitor;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @seeHowYourDeviceIsConnected.
  ///
  /// In en, this message translates to:
  /// **'See how your device is connected.'**
  String get seeHowYourDeviceIsConnected;

  /// No description provided for @measureYourConnectionAndFindWaysToImproveYourWiFi.
  ///
  /// In en, this message translates to:
  /// **'Measure your connection and find ways to improve your Wi-Fi.'**
  String get measureYourConnectionAndFindWaysToImproveYourWiFi;

  /// No description provided for @wiFiDetails.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi details'**
  String get wiFiDetails;

  /// No description provided for @internetMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Internet measurements'**
  String get internetMeasurements;

  /// No description provided for @measureThroughput.
  ///
  /// In en, this message translates to:
  /// **'Measure throughput'**
  String get measureThroughput;

  /// No description provided for @speedTestProvider.
  ///
  /// In en, this message translates to:
  /// **'Speed-test provider'**
  String get speedTestProvider;

  /// No description provided for @saveChecksOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Save checks on this device'**
  String get saveChecksOnThisDevice;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// No description provided for @readTheLinkAndNearbyAccessPointsWhereSupportedYourOperatingSystemMayRequestLocationAccessToIdentifyNetworks.
  ///
  /// In en, this message translates to:
  /// **'Read the link and nearby access points where supported. Your operating system may request location access to identify networks.'**
  String
  get readTheLinkAndNearbyAccessPointsWhereSupportedYourOperatingSystemMayRequestLocationAccessToIdentifyNetworks;

  /// No description provided for @timeASystemDnsLookupForSpeedCloudflareComAndConnectionsToCloudflareAt1111LeaveOffForALocalOnlyCheck.
  ///
  /// In en, this message translates to:
  /// **'Time a system DNS lookup for speed.cloudflare.com and connections to Cloudflare at 1.1.1.1. Leave off for a local-only check.'**
  String
  get timeASystemDnsLookupForSpeedCloudflareComAndConnectionsToCloudflareAt1111LeaveOffForALocalOnlyCheck;

  /// No description provided for @keepTheLatest100ReportsIncludingWiFiNamesDeleteStoredReportsFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Keep the latest 100 reports, including Wi-Fi names. Delete stored reports from History.'**
  String
  get keepTheLatest100ReportsIncludingWiFiNamesDeleteStoredReportsFromHistory;

  /// No description provided for @readWiFiSettings.
  ///
  /// In en, this message translates to:
  /// **'Read Wi-Fi settings'**
  String get readWiFiSettings;

  /// No description provided for @findings.
  ///
  /// In en, this message translates to:
  /// **'Findings'**
  String get findings;

  /// No description provided for @measurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// No description provided for @measurement.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get measurement;

  /// No description provided for @beforeAndAfter.
  ///
  /// In en, this message translates to:
  /// **'Before and after'**
  String get beforeAndAfter;

  /// No description provided for @before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @measurementNotes.
  ///
  /// In en, this message translates to:
  /// **'Measurement notes'**
  String get measurementNotes;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get exportReport;

  /// No description provided for @savePdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get savePdf;

  /// No description provided for @saveJson.
  ///
  /// In en, this message translates to:
  /// **'Save JSON'**
  String get saveJson;

  /// No description provided for @routerSettingsAndGuides.
  ///
  /// In en, this message translates to:
  /// **'Router settings and guides'**
  String get routerSettingsAndGuides;

  /// No description provided for @routerSettings.
  ///
  /// In en, this message translates to:
  /// **'Router settings'**
  String get routerSettings;

  /// No description provided for @openRouterPage.
  ///
  /// In en, this message translates to:
  /// **'Open router page'**
  String get openRouterPage;

  /// No description provided for @identifyRouter.
  ///
  /// In en, this message translates to:
  /// **'Identify router'**
  String get identifyRouter;

  /// No description provided for @guidedSetup.
  ///
  /// In en, this message translates to:
  /// **'Guided setup'**
  String get guidedSetup;

  /// No description provided for @wirelessSettingsGuide.
  ///
  /// In en, this message translates to:
  /// **'Wireless settings guide'**
  String get wirelessSettingsGuide;

  /// No description provided for @routerConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Router configuration'**
  String get routerConfiguration;

  /// No description provided for @readVisibleSettings.
  ///
  /// In en, this message translates to:
  /// **'Read visible settings'**
  String get readVisibleSettings;

  /// No description provided for @deleteSavedRouterData.
  ///
  /// In en, this message translates to:
  /// **'Delete saved router data'**
  String get deleteSavedRouterData;

  /// No description provided for @useHttps.
  ///
  /// In en, this message translates to:
  /// **'Use HTTPS'**
  String get useHttps;

  /// No description provided for @loadSavedAccount.
  ///
  /// In en, this message translates to:
  /// **'Load saved account'**
  String get loadSavedAccount;

  /// No description provided for @forgetAccount.
  ///
  /// In en, this message translates to:
  /// **'Forget account'**
  String get forgetAccount;

  /// No description provided for @signInAndRead.
  ///
  /// In en, this message translates to:
  /// **'Sign in and read'**
  String get signInAndRead;

  /// No description provided for @addSettingsToReport.
  ///
  /// In en, this message translates to:
  /// **'Add settings to report'**
  String get addSettingsToReport;

  /// No description provided for @rememberAccountInDeviceKeychain.
  ///
  /// In en, this message translates to:
  /// **'Remember account in device keychain'**
  String get rememberAccountInDeviceKeychain;

  /// No description provided for @deleteSavedChecks.
  ///
  /// In en, this message translates to:
  /// **'Delete saved checks'**
  String get deleteSavedChecks;

  /// No description provided for @savedChecksWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Saved checks will appear here.'**
  String get savedChecksWillAppearHere;

  /// No description provided for @deleteAllSavedChecks.
  ///
  /// In en, this message translates to:
  /// **'Delete all saved checks?'**
  String get deleteAllSavedChecks;

  /// No description provided for @deleteAllSavedRouterAccountsAndBackups.
  ///
  /// In en, this message translates to:
  /// **'Delete all saved router accounts and backups?'**
  String get deleteAllSavedRouterAccountsAndBackups;

  /// No description provided for @thisRemovesReportHistoryFromThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This removes report history from this device.'**
  String get thisRemovesReportHistoryFromThisDevice;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @changeChannel.
  ///
  /// In en, this message translates to:
  /// **'Change channel'**
  String get changeChannel;

  /// No description provided for @restorePreviousChannel.
  ///
  /// In en, this message translates to:
  /// **'Restore previous channel'**
  String get restorePreviousChannel;

  /// No description provided for @wiFiNetwork.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi network'**
  String get wiFiNetwork;

  /// No description provided for @band.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get band;

  /// No description provided for @channel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channel;

  /// No description provided for @channelWidth.
  ///
  /// In en, this message translates to:
  /// **'Channel width'**
  String get channelWidth;

  /// No description provided for @signal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get signal;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @linkRate.
  ///
  /// In en, this message translates to:
  /// **'Link rate'**
  String get linkRate;

  /// No description provided for @localAddress.
  ///
  /// In en, this message translates to:
  /// **'Local address'**
  String get localAddress;

  /// No description provided for @gateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gateway;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @dnsLookup.
  ///
  /// In en, this message translates to:
  /// **'DNS lookup'**
  String get dnsLookup;

  /// No description provided for @noActiveNetworkConnection.
  ///
  /// In en, this message translates to:
  /// **'No active network connection.'**
  String get noActiveNetworkConnection;

  /// No description provided for @noIssueFoundInTheAvailableMeasurements.
  ///
  /// In en, this message translates to:
  /// **'No issue found in the available measurements.'**
  String get noIssueFoundInTheAvailableMeasurements;

  /// No description provided for @connectionDetailsAreUnavailableTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Connection details are unavailable. Try again.'**
  String get connectionDetailsAreUnavailableTryAgain;

  /// No description provided for @weakWiFiSignal.
  ///
  /// In en, this message translates to:
  /// **'Weak Wi-Fi signal'**
  String get weakWiFiSignal;

  /// No description provided for @wiFiSecurityNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi security needs attention'**
  String get wiFiSecurityNeedsAttention;

  /// No description provided for @legacyWiFiSecurity.
  ///
  /// In en, this message translates to:
  /// **'Legacy Wi-Fi security'**
  String get legacyWiFiSecurity;

  /// No description provided for @legacy80211BIsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Legacy 802.11b is enabled'**
  String get legacy80211BIsEnabled;

  /// No description provided for @reviewTheRouterSSecurityMode.
  ///
  /// In en, this message translates to:
  /// **'Review the router’s security mode'**
  String get reviewTheRouterSSecurityMode;

  /// No description provided for @review24GhzChannelWidth.
  ///
  /// In en, this message translates to:
  /// **'Review 2.4 GHz channel width'**
  String get review24GhzChannelWidth;

  /// No description provided for @aQuieterChannelIsAvailable.
  ///
  /// In en, this message translates to:
  /// **'A quieter channel is available'**
  String get aQuieterChannelIsAvailable;

  /// No description provided for @a5GhzConnectionIsAvailable.
  ///
  /// In en, this message translates to:
  /// **'A 5 GHz connection is available'**
  String get a5GhzConnectionIsAvailable;

  /// No description provided for @wideChannelInABusyBand.
  ///
  /// In en, this message translates to:
  /// **'Wide channel in a busy band'**
  String get wideChannelInABusyBand;

  /// No description provided for @slowDnsLookup.
  ///
  /// In en, this message translates to:
  /// **'Slow DNS lookup'**
  String get slowDnsLookup;

  /// No description provided for @unevenLocalResponseTimes.
  ///
  /// In en, this message translates to:
  /// **'Uneven local response times'**
  String get unevenLocalResponseTimes;

  /// No description provided for @uploadBelowTheWiFiLinkRate.
  ///
  /// In en, this message translates to:
  /// **'Upload below the Wi-Fi link rate'**
  String get uploadBelowTheWiFiLinkRate;

  /// No description provided for @noActiveNetwork.
  ///
  /// In en, this message translates to:
  /// **'No active network'**
  String get noActiveNetwork;

  /// No description provided for @viewMeasurementsAndAvailability.
  ///
  /// In en, this message translates to:
  /// **'View measurements and availability'**
  String get viewMeasurementsAndAvailability;

  /// No description provided for @startingCheck.
  ///
  /// In en, this message translates to:
  /// **'Starting check…'**
  String get startingCheck;

  /// No description provided for @readingTheCurrentConnection.
  ///
  /// In en, this message translates to:
  /// **'Reading the current connection…'**
  String get readingTheCurrentConnection;

  /// No description provided for @readingWiFiMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Reading Wi-Fi measurements…'**
  String get readingWiFiMeasurements;

  /// No description provided for @measuringGatewayLatency.
  ///
  /// In en, this message translates to:
  /// **'Measuring gateway latency…'**
  String get measuringGatewayLatency;

  /// No description provided for @checkingDnsAndInternetLatency.
  ///
  /// In en, this message translates to:
  /// **'Checking DNS and internet latency…'**
  String get checkingDnsAndInternetLatency;

  /// No description provided for @measuringUpload.
  ///
  /// In en, this message translates to:
  /// **'Measuring upload…'**
  String get measuringUpload;

  /// No description provided for @measuringDownload.
  ///
  /// In en, this message translates to:
  /// **'Measuring download…'**
  String get measuringDownload;

  /// No description provided for @routerAdminSignIn.
  ///
  /// In en, this message translates to:
  /// **'Router admin sign-in'**
  String get routerAdminSignIn;

  /// No description provided for @adminAccount.
  ///
  /// In en, this message translates to:
  /// **'Admin account'**
  String get adminAccount;

  /// No description provided for @adminUsername.
  ///
  /// In en, this message translates to:
  /// **'Admin username'**
  String get adminUsername;

  /// No description provided for @adminPassword.
  ///
  /// In en, this message translates to:
  /// **'Admin password'**
  String get adminPassword;

  /// No description provided for @currentAdminLabel.
  ///
  /// In en, this message translates to:
  /// **'Use the admin account you set up, or the admin details on the router label if they are still current.'**
  String get currentAdminLabel;

  /// No description provided for @openRouterSignIn.
  ///
  /// In en, this message translates to:
  /// **'Open router sign-in'**
  String get openRouterSignIn;

  /// No description provided for @connectionOptions.
  ///
  /// In en, this message translates to:
  /// **'Connection options'**
  String get connectionOptions;

  /// No description provided for @accountAndScanOptions.
  ///
  /// In en, this message translates to:
  /// **'Account and scan options'**
  String get accountAndScanOptions;

  /// No description provided for @compareTheseChecks.
  ///
  /// In en, this message translates to:
  /// **'Compare these two checks'**
  String get compareTheseChecks;

  /// No description provided for @viewBaseline.
  ///
  /// In en, this message translates to:
  /// **'View your baseline check'**
  String get viewBaseline;

  /// No description provided for @yourBaseline.
  ///
  /// In en, this message translates to:
  /// **'Your baseline check'**
  String get yourBaseline;

  /// No description provided for @baseline.
  ///
  /// In en, this message translates to:
  /// **'Baseline'**
  String get baseline;

  /// No description provided for @baselineHelp.
  ///
  /// In en, this message translates to:
  /// **'Run another check on this access point after making a change to see both measurements here.'**
  String get baselineHelp;

  /// No description provided for @speedComparison.
  ///
  /// In en, this message translates to:
  /// **'Speed comparison'**
  String get speedComparison;

  /// No description provided for @wifiLinkRate.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi link rate'**
  String get wifiLinkRate;

  /// No description provided for @afterLabel.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get afterLabel;

  /// No description provided for @selectRouterFamily.
  ///
  /// In en, this message translates to:
  /// **'Router family'**
  String get selectRouterFamily;

  /// No description provided for @httpDisclosure.
  ///
  /// In en, this message translates to:
  /// **'HTTP sends login details across your Wi-Fi without encryption.'**
  String get httpDisclosure;

  /// No description provided for @saveRecheck.
  ///
  /// In en, this message translates to:
  /// **'Save and recheck'**
  String get saveRecheck;

  /// No description provided for @hideGuide.
  ///
  /// In en, this message translates to:
  /// **'Hide guide'**
  String get hideGuide;

  /// No description provided for @showGuide.
  ///
  /// In en, this message translates to:
  /// **'Show guide'**
  String get showGuide;

  /// No description provided for @startSteps.
  ///
  /// In en, this message translates to:
  /// **'Start steps'**
  String get startSteps;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// No description provided for @reviewChanges.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get reviewChanges;

  /// No description provided for @finishGuide.
  ///
  /// In en, this message translates to:
  /// **'Finish guide'**
  String get finishGuide;

  /// No description provided for @backGuide.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backGuide;

  /// No description provided for @modeLabel.
  ///
  /// In en, this message translates to:
  /// **'Wireless mode'**
  String get modeLabel;

  /// No description provided for @chanLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel selection'**
  String get chanLabel;

  /// No description provided for @secLabel.
  ///
  /// In en, this message translates to:
  /// **'Wireless security'**
  String get secLabel;

  /// No description provided for @wireless2g.
  ///
  /// In en, this message translates to:
  /// **'Wireless · 2.4 GHz'**
  String get wireless2g;

  /// No description provided for @wirelessSec.
  ///
  /// In en, this message translates to:
  /// **'Wireless · Security'**
  String get wirelessSec;

  /// No description provided for @guideIntro.
  ///
  /// In en, this message translates to:
  /// **'After signing in, start the steps for your check. Note the original settings before editing.'**
  String get guideIntro;

  /// No description provided for @guideEnd.
  ///
  /// In en, this message translates to:
  /// **'Review your selections on the router page and save the changes you want. Reconnect to this Wi-Fi, then run Check again in witor to compare the results.'**
  String get guideEnd;

  /// No description provided for @guideProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String guideProgress(int current, int total);
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
