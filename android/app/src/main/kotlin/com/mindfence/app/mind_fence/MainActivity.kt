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
import android.content.ComponentName
import android.app.admin.DevicePolicyManager
import android.net.Uri

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mindfence.app/device_control"
    private lateinit var sharedPreferences: SharedPreferences
    private val VPN_REQUEST_CODE = 1001
    private var vpnPermissionResult: MethodChannel.Result? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        sharedPreferences = getSharedPreferences("mind_fence_prefs", Context.MODE_PRIVATE)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
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
                    "requestAllPermissions" -> {
                        requestAllPermissions()
                        result.success(null)
                    }
                    "openAppSettings" -> {
                        openAppSettings()
                        result.success(null)
                    }
                    "hasAccessibilityPermission" -> {
                        result.success(hasAccessibilityPermission())
                    }
                    "requestDeviceAdminPermission" -> {
                        requestDeviceAdminPermission()
                        result.success(null)
                    }
                    "hasDeviceAdminPermission" -> {
                        result.success(hasDeviceAdminPermission())
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
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Method channel error: ${call.method}", e)
                result.error("ERROR", "Failed to execute ${call.method}: ${e.message}", null)
            }
        }
    }
    
    private fun requestUsageStatsPermission() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            // Try to direct to our app's usage stats permission page
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                intent.data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to request usage stats permission", e)
        }
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
        try {
            // Try to open the specific accessibility service settings first
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            
            // Add extra to potentially highlight our service (Android 10+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                intent.putExtra(":settings:fragment_args_key", "${packageName}/${AccessibilityService::class.java.canonicalName}")
            }
            
            startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to request accessibility permission", e)
            // Fallback to general settings
            try {
                val fallbackIntent = Intent(Settings.ACTION_SETTINGS)
                startActivity(fallbackIntent)
            } catch (fallbackException: Exception) {
                android.util.Log.e("MainActivity", "Failed to open settings", fallbackException)
            }
        }
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
    
    private fun hasDeviceAdminPermission(): Boolean {
        val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(this, DeviceAdminReceiver::class.java)
        return devicePolicyManager.isAdminActive(componentName)
    }
    
    private fun requestDeviceAdminPermission() {
        try {
            val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val componentName = ComponentName(this, DeviceAdminReceiver::class.java)
            
            if (!devicePolicyManager.isAdminActive(componentName)) {
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                    "Mind Fence needs device admin permission to block apps effectively")
                startActivity(intent)
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to request device admin permission", e)
        }
    }
    
    private fun requestOverlayPermission() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to request overlay permission", e)
        }
    }
    
    private fun requestAllPermissions() {
        try {
            // Open the app's main settings page where all permissions can be managed
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to request all permissions", e)
            // Fallback to general settings
            try {
                val fallbackIntent = Intent(Settings.ACTION_SETTINGS)
                startActivity(fallbackIntent)
            } catch (fallbackException: Exception) {
                android.util.Log.e("MainActivity", "Failed to open settings", fallbackException)
            }
        }
    }
    
    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to open app settings", e)
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