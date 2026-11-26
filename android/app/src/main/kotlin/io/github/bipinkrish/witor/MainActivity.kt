package io.github.bipinkrish.witor

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.ScanResult
import android.net.wifi.WifiManager
import android.os.Build
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "witor/wifi").setMethodCallHandler { call, result ->
            if (call.method != "snapshot") {
                result.notImplemented()
            } else if (pending != null) {
                result.error("busy", "Permission request in progress", null)
            } else if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                readRadio(result, true)
            } else {
                pending = result
                requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), 738)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grants: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grants)
        if (requestCode == 738) {
            val result = pending ?: return
            pending = null
            readRadio(result, checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED)
        }
    }

    @Suppress("DEPRECATION")
    private fun readRadio(result: MethodChannel.Result, allowed: Boolean) {
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val info = wifi.connectionInfo
            val link = mutableMapOf<String, Any>()
            if (info.frequency > 0) link["frequency"] = info.frequency
            if (info.rssi in -126..-1) link["rssi"] = info.rssi
            if (info.linkSpeed > 0) link["txRate"] = info.linkSpeed
            val entries = if (allowed) wifi.scanResults else emptyList()
            val nearby = entries.map { ap ->
                val row = mutableMapOf<String, Any>("ssid" to ap.SSID, "bssid" to ap.BSSID, "rssi" to ap.level, "frequency" to ap.frequency)
                val width = when (ap.channelWidth) {
                    ScanResult.CHANNEL_WIDTH_20MHZ -> 20
                    ScanResult.CHANNEL_WIDTH_40MHZ -> 40
                    ScanResult.CHANNEL_WIDTH_80MHZ -> 80
                    ScanResult.CHANNEL_WIDTH_160MHZ, ScanResult.CHANNEL_WIDTH_80MHZ_PLUS_MHZ -> 160
                    5 -> 320
                    else -> null
                }
                if (width != null) row["width"] = width
                row["ageSeconds"] = ((SystemClock.elapsedRealtimeNanos() / 1000 - ap.timestamp) / 1000000).coerceAtLeast(0)
                val caps = ap.capabilities.orEmpty()
                val security = when {
                    caps.contains("SAE") -> "WPA3"
                    caps.contains("WPA-") && caps.contains("WPA2") -> "WPA/WPA2"
                    caps.contains("WPA2") || caps.contains("RSN") -> "WPA2"
                    caps.contains("WPA") -> "WPA"
                    caps.contains("WEP") -> "WEP"
                    caps.contains("OWE") -> "Enhanced Open"
                    caps == "[ESS]" -> "Open"
                    else -> null
                }
                if (security != null) row["security"] = security + if (caps.contains("TKIP")) " · TKIP" else ""
                row
            }
            nearby.firstOrNull { it["bssid"] == info.bssid }?.let { link.putAll(it) }
            if (allowed && info.ssid != "<unknown ssid>") link["ssid"] = info.ssid.trim('"')
            if (allowed && info.bssid != null && info.bssid != "02:00:00:00:00:00") link["bssid"] = info.bssid
            if (info.rssi in -126..-1) link["rssi"] = info.rssi
            if (Build.VERSION.SDK_INT >= 30) {
                val standard = mapOf(4 to "802.11n", 5 to "802.11ac", 6 to "802.11ax", 8 to "802.11be")[info.wifiStandard]
                if (standard != null) link["phy"] = standard
            }
            val note = if (!allowed) "Location permission was declined. Nearby networks are unavailable."
                else "Cached Android scan results. Android controls when the scan cache is refreshed."
            result.success(mapOf("link" to link, "nearby" to nearby, "note" to note))
        } catch (e: SecurityException) {
            result.success(mapOf("note" to "Android restricted access to Wi-Fi measurements. Check location permission and Location Services."))
        }
    }
}
