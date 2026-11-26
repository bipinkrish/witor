import CoreLocation
import Flutter
import NetworkExtension
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private let location = CLLocationManager()
  private var pending: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    location.delegate = self
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name: "witor/wifi", binaryMessenger: controller.binaryMessenger)
        .setMethodCallHandler { [weak self] call, result in
          guard call.method == "snapshot", let self = self else { result(FlutterMethodNotImplemented); return }
          guard self.pending == nil else { result(FlutterError(code: "busy", message: "Check in progress", details: nil)); return }
          self.pending = result
          if CLLocationManager.authorizationStatus() == .notDetermined {
            self.location.requestWhenInUseAuthorization()
          } else { self.readNetwork() }
        }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if status != .notDetermined { readNetwork() }
  }

  private func readNetwork() {
    guard let result = pending else { return }
    pending = nil
    let note = "iOS does not provide nearby Wi-Fi scans or link signal measurements to this app."
    guard #available(iOS 14, *) else { result(["note": note]); return }
    NEHotspotNetwork.fetchCurrent { network in
      var link: [String: Any] = [:]
      if let network = network {
        link["ssid"] = network.ssid
        link["bssid"] = network.bssid
        if #available(iOS 15, *) {
          switch network.securityType {
          case .open: link["security"] = "Open"
          case .WEP: link["security"] = "WEP"
          case .personal: link["security"] = "Personal"
          case .enterprise: link["security"] = "Enterprise"
          default: break
          }
        }
      }
      result(["link": link, "note": note])
    }
  }
}
