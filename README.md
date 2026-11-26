# witor

witor checks the Wi-Fi connection on the device running the app. Run **Check connection**, then open **Check report** to see the measured link, findings and suggested fixes. Run it again after moving the device or changing a setting to compare checks for the same access point.

The Android application ID, Apple bundle ID and Linux application ID are `io.github.bipinkrish.witor`.

## Run from this folder

Use Flutter 3.35.2 and Dart 3.9. Install Android SDK tools for Android, Xcode on a Mac for Apple targets, or the Visual Studio C++ desktop workload for Windows. Linux needs the Flutter desktop toolchain, GTK 3, NetworkManager and libsecret development headers. On Ubuntu install `libsecret-1-dev` for the build and `libsqlite3-dev` for SQLite-based unit tests.

```sh
flutter pub get
flutter devices
flutter run -d linux
```

## Measurements and privacy

- Android reads the OS Wi-Fi scan cache, macOS uses CoreWLAN, Windows uses WLAN APIs, and Linux reads NetworkManager. Available fields depend on the radio, permissions and OS. iOS can report the connected network and can use a supported router for a neighbouring-network scan.
- Gateway timing uses ICMP on supported hosts with a working ping command. The fallback opens one TCP connection. The report names the protocol so packet loss and timings can be interpreted correctly.
- Internet timing and speed tests are optional. Timing checks use Cloudflare. Speed tests use the selected provider, Cloudflare or M-Lab NDT7. M-Lab publishes test results including the public IP address. The provider receives the test traffic directly.
- History stores up to 100 checks locally. Settings can disable history or erase it. Reports exported as PDF or JSON can contain the Wi-Fi name and local network addresses. Router accounts are saved only on request in device secure storage.
- The main interface supports English and Hindi. Some detailed measurements and router instructions use English.

## Router support

Open router settings from a current Wi-Fi report. witor checks the gateway and available network identity before contacting the router. Identification and sign-in are separate actions. The owner can choose a guided workflow or use their external browser. 

| Router | Implemented path |
| --- | --- |
| Realtek / Boa, including the recorded Dragon Path 707GR1 | Guided settings and capture of selected visible radio fields in the embedded browser. Linux uses the external browser for manual changes. |
| OpenWrt | Authenticated wireless settings, optional nearby scan, wireless client count and WAN address classification through ubus when the account has permission. |
| FRITZ!Box | WLAN information through supported TR-064 services with a subscriber account. |
| Other listed families | Family-specific navigation and manual changes in the router interface or provider app. |

The OpenWrt channel-change implementation includes encrypted backup, timed rollback, readback and undo. Its allowlist is empty until an exact hardware and firmware combination passes the real-router acceptance test. The Dragon Path field study documents manual changes. Automated writes, additional vendor protocols, platform device testing, beta distribution and store releases remain open.

## Verify

```sh
flutter analyze
flutter test
flutter test integration_test -d linux
flutter build apk --debug
flutter build linux --release
```

Tests cover the [Dragon Path field measurements](test/fixtures/dragon_path_707gr1.json), channel selection, history, export, router request pacing and rollback. The integration test runs a check through the host platform plugin and opens its report. Platform builds in GitHub Actions use their respective host toolchains.
