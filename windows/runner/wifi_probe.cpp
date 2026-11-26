#include "wifi_probe.h"

#include <windows.h>
#include <wlanapi.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <cstdio>
#include <memory>
#include <string>

namespace {
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;

struct WlanMemory {
  void operator()(void* p) const { WlanFreeMemory(p); }
};
struct WlanHandle {
  HANDLE handle = nullptr;
  ~WlanHandle() { if (handle) WlanCloseHandle(handle, nullptr); }
};
std::string Bssid(const UCHAR* bytes) {
  char text[18];
  std::snprintf(text, sizeof(text), "%02x:%02x:%02x:%02x:%02x:%02x",
                bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5]);
  return text;
}
std::string Ssid(const DOT11_SSID& ssid) {
  std::string name(reinterpret_cast<const char*>(ssid.ucSSID), ssid.uSSIDLength);
  if (!name.empty() && !MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, name.data(),
                                             static_cast<int>(name.size()), nullptr, 0)) return {};
  return name;
}
Map Snapshot() {
  WlanHandle api;
  DWORD version = 0;
  Map result;
  result[Value("note")] = Value("Windows did not provide Wi-Fi details. Check precise location access in Settings.");
  if (WlanOpenHandle(2, nullptr, &version, &api.handle) != ERROR_SUCCESS) return result;
  WLAN_INTERFACE_INFO_LIST* raw = nullptr;
  if (WlanEnumInterfaces(api.handle, nullptr, &raw) != ERROR_SUCCESS) return result;
  std::unique_ptr<WLAN_INTERFACE_INFO_LIST,WlanMemory> interfaces(raw);
  for (DWORD i=0; i<raw->dwNumberOfItems; ++i) {
    const auto& interfaceInfo = raw->InterfaceInfo[i];
    if (interfaceInfo.isState != wlan_interface_state_connected) continue;
    DWORD size = 0;
    void* buffer = nullptr;
    if (WlanQueryInterface(api.handle,&interfaceInfo.InterfaceGuid,wlan_intf_opcode_current_connection,
                           nullptr,&size,&buffer,nullptr) != ERROR_SUCCESS) continue;
    std::unique_ptr<void,WlanMemory> connection(buffer);
    auto* info = static_cast<WLAN_CONNECTION_ATTRIBUTES*>(buffer);
    const auto& assoc = info->wlanAssociationAttributes;
    auto current = Bssid(assoc.dot11Bssid);
    Map link{{Value("ssid"),Value(Ssid(assoc.dot11Ssid))},{Value("bssid"),Value(current)},
             {Value("quality"),Value(static_cast<int>(assoc.wlanSignalQuality))},
             {Value("txRate"),Value(assoc.ulTxRate / 1000.0)}};
    const auto& security = info->wlanSecurityAttributes;
    if (!security.bSecurityEnabled) link[Value("security")] = Value("Open");
    else if (security.dot11CipherAlgorithm == DOT11_CIPHER_ALGO_TKIP) link[Value("security")] = Value("TKIP");
    else if (security.dot11CipherAlgorithm == DOT11_CIPHER_ALGO_WEP || security.dot11CipherAlgorithm == DOT11_CIPHER_ALGO_WEP40 || security.dot11CipherAlgorithm == DOT11_CIPHER_ALGO_WEP104) link[Value("security")] = Value("WEP");
    WLAN_BSS_LIST* list = nullptr;
    if (WlanGetNetworkBssList(api.handle,&interfaceInfo.InterfaceGuid,nullptr,dot11_BSS_type_any,FALSE,nullptr,&list) == ERROR_SUCCESS) {
      std::unique_ptr<WLAN_BSS_LIST,WlanMemory> networks(list);
      flutter::EncodableList nearby;
      for (DWORD j=0; j<list->dwNumberOfItems; ++j) {
        const auto& bss = list->wlanBssEntries[j];
        const auto id = Bssid(bss.dot11Bssid);
        Value frequency(static_cast<int>(bss.ulChCenterFrequency/1000));
        Value signal(static_cast<int>(bss.lRssi));
        nearby.emplace_back(Map{{Value("ssid"), Value(Ssid(bss.dot11Ssid))},{Value("bssid"),Value(id)},
                                {Value("frequency"),frequency},{Value("rssi"),signal}});
        if (id==current) { link[Value("frequency")] = frequency; link[Value("rssi")] = signal; }
      }
      result[Value("nearby")] = Value(nearby);
      result[Value("note")] = Value("Cached access points from Windows Native Wi-Fi.");
    }
    result[Value("link")] = Value(link);
    break;
  }
  return result;
}
}
void RegisterWifiProbe(flutter::BinaryMessenger* messenger) {
  flutter::MethodChannel<Value> channel(messenger,"witor/wifi",&flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name()=="snapshot") result->Success(Value(Snapshot()));
    else result->NotImplemented();
  });
}
