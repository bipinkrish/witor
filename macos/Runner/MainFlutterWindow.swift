import Cocoa
import CoreLocation
import CoreWLAN
import FlutterMacOS

class MainFlutterWindow: NSWindow, CLLocationManagerDelegate {
  private let location = CLLocationManager()
  private var pending: FlutterResult?

  override func awakeFromNib() {
    let controller = FlutterViewController()
    let originalFrame = frame
    contentViewController = controller
    setFrame(originalFrame, display: true)
    RegisterGeneratedPlugins(registry: controller)
    location.delegate = self
    FlutterMethodChannel(name: "witor/wifi", binaryMessenger: controller.engine.binaryMessenger)
      .setMethodCallHandler { [weak self] call, result in
        guard call.method == "snapshot", let self = self else { result(FlutterMethodNotImplemented); return }
        guard self.pending == nil else { result(FlutterError(code: "busy", message: "Check in progress", details: nil)); return }
        self.pending = result
        if CLLocationManager.authorizationStatus() == .notDetermined { self.location.requestWhenInUseAuthorization() }
        else { self.readRadio() }
      }
    super.awakeFromNib()
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if status != .notDetermined { readRadio() }
  }

  private static func channelFields(_ channel: CWChannel?) -> [String: Any] {
    guard let c = channel else { return [:] }
    var fields: [String: Any] = ["channel": c.channelNumber]
    if let width = [1:20, 2:40, 3:80, 4:160][c.channelWidth.rawValue] { fields["width"] = width }
    fields["band"] = [1:"2.4 GHz", 2:"5 GHz", 3:"6 GHz"][c.channelBand.rawValue]
    return fields
  }

  private func readRadio() {
    guard let result = pending else { return }
    pending = nil
    DispatchQueue.global(qos: .userInitiated).async {
      var link: [String: Any] = [:]
      var nearby: [[String: Any]] = []
      var note = "Nearby access points measured by CoreWLAN."
      if let wifi = CWWiFiClient.shared().interface() {
        link = Self.channelFields(wifi.wlanChannel())
        link["ssid"] = wifi.ssid()
        link["bssid"] = wifi.bssid()
        if wifi.rssiValue() < 0 { link["rssi"] = wifi.rssiValue() }
        if wifi.transmitRate() > 0 { link["txRate"] = wifi.transmitRate() }
        switch wifi.security() {
        case .none: link["security"] = "Open"
        case .WEP, .dynamicWEP: link["security"] = "WEP"
        case .wpaPersonalMixed, .wpaEnterpriseMixed: link["security"] = "WPA/WPA2"
        case .wpa2Personal, .wpa2Enterprise: link["security"] = "WPA2"
        case .wpa3Personal, .wpa3Enterprise, .wpa3Transition: link["security"] = "WPA3"
        default: break
        }
        do {
          nearby = try wifi.scanForNetworks(withName: nil).map { network in
            var row = Self.channelFields(network.wlanChannel)
            row["ssid"] = network.ssid
            row["bssid"] = network.bssid
            row["rssi"] = network.rssiValue
            return row
          }
        } catch { note = "macOS did not return a nearby scan. Check Location Services for witor." }
      } else { note = "No Wi-Fi interface is available." }
      let snapshot: [String: Any] = ["link": link, "nearby": nearby, "note": note]
      DispatchQueue.main.async { result(snapshot) }
    }
  }
}
