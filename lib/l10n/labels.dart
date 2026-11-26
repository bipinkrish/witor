import 'package:flutter/material.dart';
import 'generated/app_localizations.dart';

String uiLabel(BuildContext context, String value) {
  final words = AppLocalizations.of(context)!;
  return switch (value) {
    "Wi-Fi check" => words.wiFiCheck,
    "Connection details" => words.connectionDetails,
    "Network type" => words.networkType,
    "Last checked" => words.lastChecked,
    "Check connection" => words.checkConnection,
    "Check again" => words.checkAgain,
    "Checking…" => words.checking,
    "Not checked yet" => words.notCheckedYet,
    "Check report" => words.checkReport,
    "Check settings" => words.checkSettings,
    "History" => words.history,
    "About witor" => words.aboutWitor,
    "Done" => words.done,
    "Cancel" => words.cancel,
    "Delete" => words.delete,
    "See how your device is connected." => words.seeHowYourDeviceIsConnected,
    "Measure your connection and find ways to improve your Wi-Fi." =>
      words.measureYourConnectionAndFindWaysToImproveYourWiFi,
    "Wi-Fi details" => words.wiFiDetails,
    "Internet measurements" => words.internetMeasurements,
    "Measure throughput" => words.measureThroughput,
    "Speed-test provider" => words.speedTestProvider,
    "Save checks on this device" => words.saveChecksOnThisDevice,
    "Save settings" => words.saveSettings,
    "Read the link and nearby access points where supported. Your operating system may request location access to identify networks." =>
      words
          .readTheLinkAndNearbyAccessPointsWhereSupportedYourOperatingSystemMayRequestLocationAccessToIdentifyNetworks,
    "Time a system DNS lookup for speed.cloudflare.com and connections to Cloudflare at 1.1.1.1. Leave off for a local-only check." =>
      words
          .timeASystemDnsLookupForSpeedCloudflareComAndConnectionsToCloudflareAt1111LeaveOffForALocalOnlyCheck,
    "Keep the latest 100 reports, including Wi-Fi names. Delete stored reports from History." =>
      words
          .keepTheLatest100ReportsIncludingWiFiNamesDeleteStoredReportsFromHistory,
    "Read Wi-Fi settings" => words.readWiFiSettings,
    "Findings" => words.findings,
    "Measurements" => words.measurements,
    "Measurement" => words.measurement,
    "Before and after" => words.beforeAndAfter,
    "Before" => words.before,
    "Current" => words.current,
    "Measurement notes" => words.measurementNotes,
    "Export report" => words.exportReport,
    "Save PDF" => words.savePdf,
    "Save JSON" => words.saveJson,
    "Router settings and guides" => words.routerSettingsAndGuides,
    "Router settings" => words.routerSettings,
    "Open router page" => words.openRouterPage,
    "Identify router" => words.identifyRouter,
    "Guided setup" => words.guidedSetup,
    "Wireless settings guide" => words.wirelessSettingsGuide,
    "Router configuration" => words.routerConfiguration,
    "Read visible settings" => words.readVisibleSettings,
    "Delete saved router data" => words.deleteSavedRouterData,
    "Use HTTPS" => words.useHttps,
    "Load saved account" => words.loadSavedAccount,
    "Forget account" => words.forgetAccount,
    "Sign in and read" => words.signInAndRead,
    "Add settings to report" => words.addSettingsToReport,
    "Remember account in device keychain" =>
      words.rememberAccountInDeviceKeychain,
    "Delete saved checks" => words.deleteSavedChecks,
    "Saved checks will appear here." => words.savedChecksWillAppearHere,
    "Delete all saved checks?" => words.deleteAllSavedChecks,
    "Delete all saved router accounts and backups?" =>
      words.deleteAllSavedRouterAccountsAndBackups,
    "This removes report history from this device." =>
      words.thisRemovesReportHistoryFromThisDevice,
    "Apply" => words.apply,
    "Change channel" => words.changeChannel,
    "Restore previous channel" => words.restorePreviousChannel,
    "Wi-Fi network" => words.wiFiNetwork,
    "Band" => words.band,
    "Channel" => words.channel,
    "Channel width" => words.channelWidth,
    "Signal" => words.signal,
    "Security" => words.security,
    "Link rate" => words.linkRate,
    "Local address" => words.localAddress,
    "Gateway" => words.gateway,
    "Download" => words.download,
    "Upload" => words.upload,
    "DNS lookup" => words.dnsLookup,
    "No active network connection." => words.noActiveNetworkConnection,
    "No issue found in the available measurements." =>
      words.noIssueFoundInTheAvailableMeasurements,
    "Connection details are unavailable. Try again." =>
      words.connectionDetailsAreUnavailableTryAgain,
    "Weak Wi-Fi signal" => words.weakWiFiSignal,
    "Wi-Fi security needs attention" => words.wiFiSecurityNeedsAttention,
    "Legacy Wi-Fi security" => words.legacyWiFiSecurity,
    "Legacy 802.11b is enabled" => words.legacy80211BIsEnabled,
    "Review the router’s security mode" => words.reviewTheRouterSSecurityMode,
    "Review 2.4 GHz channel width" => words.review24GhzChannelWidth,
    "A quieter channel is available" => words.aQuieterChannelIsAvailable,
    "A 5 GHz connection is available" => words.a5GhzConnectionIsAvailable,
    "Wide channel in a busy band" => words.wideChannelInABusyBand,
    "Slow DNS lookup" => words.slowDnsLookup,
    "Uneven local response times" => words.unevenLocalResponseTimes,
    "Upload below the Wi-Fi link rate" => words.uploadBelowTheWiFiLinkRate,
    "No active network" => words.noActiveNetwork,
    "View measurements and availability" =>
      words.viewMeasurementsAndAvailability,
    "Starting check…" => words.startingCheck,
    "Reading the current connection…" => words.readingTheCurrentConnection,
    "Reading Wi-Fi measurements…" => words.readingWiFiMeasurements,
    "Measuring gateway latency…" => words.measuringGatewayLatency,
    "Checking DNS and internet latency…" => words.checkingDnsAndInternetLatency,
    "Measuring upload…" => words.measuringUpload,
    "Measuring download…" => words.measuringDownload,
    "Router admin sign-in" => words.routerAdminSignIn,
    "Admin account" => words.adminAccount,
    "Admin username" => words.adminUsername,
    "Admin password" => words.adminPassword,
    "Use the admin account you set up, or the admin details on the router label if they are still current." =>
      words.currentAdminLabel,
    "Open router sign-in" => words.openRouterSignIn,
    "Connection options" => words.connectionOptions,
    "Account and scan options" => words.accountAndScanOptions,
    "Compare these two checks" => words.compareTheseChecks,
    "View your baseline check" => words.viewBaseline,
    "Your baseline check" => words.yourBaseline,
    "Baseline" => words.baseline,
    "Run another check on this access point after making a change to see both measurements here." =>
      words.baselineHelp,
    "Speed comparison" => words.speedComparison,
    "Wi-Fi link rate" => words.wifiLinkRate,
    "After" => words.afterLabel,
    "Router family" => words.selectRouterFamily,
    "HTTP sends login details across your Wi-Fi without encryption." =>
      words.httpDisclosure,
    "Save and recheck" => words.saveRecheck,
    "Hide guide" => words.hideGuide,
    "Show guide" => words.showGuide,
    "Start steps" => words.startSteps,
    "Next step" => words.nextStep,
    "Review changes" => words.reviewChanges,
    "Finish guide" => words.finishGuide,
    "Back" => words.backGuide,
    "Wireless mode" => words.modeLabel,
    "Channel selection" => words.chanLabel,
    "Wireless security" => words.secLabel,
    "Wireless \u00b7 2.4 GHz" => words.wireless2g,
    "Wireless \u00b7 Security" => words.wirelessSec,
    "After signing in, start the steps for your check. Note the original settings before editing." =>
      words.guideIntro,
    "Review your selections on the router page and save the changes you want. Reconnect to this Wi-Fi, then run Check again in witor to compare the results." =>
      words.guideEnd,
    _ => value,
  };
}

class UiText extends StatelessWidget {
  const UiText(this.value, {super.key, this.style});
  final String value;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) =>
      Text(uiLabel(context, value), style: style);
}
