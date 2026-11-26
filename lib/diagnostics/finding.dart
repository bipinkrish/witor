enum RouterSetting {
  mode('Wireless mode', 'Wireless · 2.4 GHz'),
  width('Channel width', 'Wireless · 2.4 GHz'),
  channel('Channel selection', 'Wireless · 2.4 GHz'),
  security('Wireless security', 'Wireless · Security');

  const RouterSetting(this.label, this.location);
  final String label;
  final String location;
}

class Finding {
  const Finding(this.title, this.evidence, this.action, {this.setting});
  final String title;
  final String evidence;
  final String action;
  final RouterSetting? setting;
}

/// One instruction per control. Router observations precede device observations
/// in the report, so keep their more specific configuration evidence.
List<Finding> routerGuideSteps(Iterable<Finding> findings) {
  final bySetting = <RouterSetting, Finding>{};
  for (final finding in findings) {
    final setting = finding.setting;
    if (setting != null) bySetting.putIfAbsent(setting, () => finding);
  }
  return [for (final setting in RouterSetting.values) ?bySetting[setting]];
}
