package com.mindfence.app.mind_fence

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import android.content.SharedPreferences
import android.net.VpnService
import android.app.Activity
import android.provider.Settings.Secure
import android.text.TextUtils

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mindfence.app/device_control"
    private lateinit var sharedPreferences: SharedPreferences
    private val VPN_REQUEST_CODE = 1001
    private var vpnPermissionResult: MethodChannel.Result? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        sharedPreferences = getSharedPreferences("mind_fence_prefs", Context.MODE_PRIVATE)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(null)
                }
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(null)
                }
                "hasAccessibilityPermission" -> {
                    result.success(hasAccessibilityPermission())
                }
                "requestDeviceAdminPermission" -> {
                    requestDeviceAdminPermission()
                    result.success(null)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "getInstalledApps" -> {
                    getInstalledApps(result)
                }
                "startBlocking" -> {
                    val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                    startBlocking(blockedApps)
                    result.success(null)
                }
                "stopBlocking" -> {
                    stopBlocking()
                    result.success(null)
                }
                "updateBlockedApps" -> {
                    val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                    updateBlockedApps(blockedApps)
                    result.success(null)
                }
                "isBlocking" -> {
                    result.success(isBlocking())
                }
                "requestVpnPermission" -> {
                    requestVpnPermission(result)
                }
                "startVpn" -> {
                    val blockedDomains = call.argument<List<String>>("blockedDomains") ?: emptyList()
                    startVpn(blockedDomains)
                    result.success(null)
                }
                "stopVpn" -> {
                    stopVpn()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }
    
    private fun hasUsageStatsPermission(): Boolean {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            time - 1000 * 60,
            time
        )
        return stats != null && stats.isNotEmpty()
    }
    
    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }
    
    private fun hasAccessibilityPermission(): Boolean {
        val accessibilityEnabled: Int = try {
            Secure.getInt(
                applicationContext.contentResolver,
                Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Exception) {
            0
        }
        
        if (accessibilityEnabled == 1) {
            val service = "${packageName}/${AccessibilityService::class.java.canonicalName}"
            val enabledServices = Secure.getString(
                applicationContext.contentResolver,
                Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            return enabledServices?.contains(service) ?: false
        }
        return false
    }
    
    private fun requestDeviceAdminPermission() {
        // TODO: Implement device admin permission request
        val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
        startActivity(intent)
    }
    
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
            startActivity(intent)
        }
    }
    
    @RequiresApi(Build.VERSION_CODES.M)
    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }
    
    private fun getInstalledApps(result: MethodChannel.Result) {
        try {
            val packageManager = applicationContext.packageManager
            val packages = packageManager.getInstalledApplications(0)
            
            val appList = packages.map { appInfo ->
                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to packageManager.getApplicationLabel(appInfo).toString(),
                    "isSystemApp" to ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0)
                )
            }.filter { app ->
                // Filter out system apps
                !(app["isSystemApp"] as Boolean)
            }
            
            result.success(appList)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to get installed apps: ${e.message}", null)
        }
    }
    
    private fun startBlocking(blockedApps: List<String>) {
        try {
            // Store blocked apps in shared preferences
            sharedPreferences.edit()
                .putString("blocked_apps", blockedApps.joinToString(","))
                .putBoolean("is_blocking", true)
                .apply()
            
            // Start the blocking service
            BlockingService.startBlocking(this, blockedApps)
        } catch (e: Exception) {
            // Handle error
        }
    }
    
    private fun stopBlocking() {
        try {
            // Update blocking status
            sharedPreferences.edit()
                .putBoolean("is_blocking", false)
                .apply()
            
            // Stop the blocking service
            BlockingService.stopBlocking(this)
        } catch (e: Exception) {
            // Handle error
        }
    }
    
    private fun updateBlockedApps(blockedApps: List<String>) {
        try {
            // Update blocked apps in shared preferences
            sharedPreferences.edit()
                .putString("blocked_apps", blockedApps.joinToString(","))
                .apply()
            
            // Update the blocking service
            BlockingService.updateBlockedApps(this, blockedApps)
        } catch (e: Exception) {
            // Handle error
        }
    }
    
    private fun isBlocking(): Boolean {
        return sharedPreferences.getBoolean("is_blocking", false)
    }
    
    private fun requestVpnPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            vpnPermissionResult = result
            startActivityForResult(intent, VPN_REQUEST_CODE)
        } else {
            result.success(true)
        }
    }
    
    private fun startVpn(blockedDomains: List<String>) {
        try {
            com.mindfence.app.mind_fence.VpnService.startVpn(this, blockedDomains)
        } catch (e: Exception) {
            // Handle error
        }
    }
    
    private fun stopVpn() {
        try {
            com.mindfence.app.mind_fence.VpnService.stopVpn(this)
        } catch (e: Exception) {
            // Handle error
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == VPN_REQUEST_CODE) {
            vpnPermissionResult?.let { result ->
                if (resultCode == Activity.RESULT_OK) {
                    result.success(true)
                } else {
                    result.success(false)
                }
            }
            vpnPermissionResult = null
        }
    }
}