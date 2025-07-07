package com.mindfence.app.mind_fence

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent
import android.app.ActivityManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log

class AccessibilityService : AccessibilityService() {
    
    private val TAG = "MindFenceAccessibility"
    private var blockedApps: Set<String> = emptySet()
    private var isBlocking = false
    private lateinit var sharedPreferences: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private val checkInterval = 1000L // Check every second
    private var monitoringRunnable: Runnable? = null
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "AccessibilityService connected")
        
        sharedPreferences = getSharedPreferences("mind_fence_prefs", Context.MODE_PRIVATE)
        loadBlockedApps()
        
        // Configure accessibility service
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.packageNames = null // Monitor all packages
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.notificationTimeout = 100
        info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        serviceInfo = info
        
        startMonitoring()
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            if (packageName != null && shouldBlockApp(packageName)) {
                Log.d(TAG, "Blocking app: $packageName")
                blockApp(packageName)
            }
        }
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted")
        stopMonitoring()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AccessibilityService destroyed")
        stopMonitoring()
    }
    
    private fun startMonitoring() {
        monitoringRunnable = object : Runnable {
            override fun run() {
                // Reload blocking state and apps on each check
                loadBlockedApps()
                if (isBlocking) {
                    checkForegroundApp()
                }
                handler.postDelayed(this, checkInterval)
            }
        }
        handler.post(monitoringRunnable!!)
    }
    
    private fun stopMonitoring() {
        monitoringRunnable?.let {
            handler.removeCallbacks(it)
        }
    }
    
    private fun checkForegroundApp() {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningTasks = activityManager.getRunningTasks(1)
        
        if (runningTasks.isNotEmpty()) {
            val topActivity = runningTasks[0].topActivity
            val packageName = topActivity?.packageName
            
            if (packageName != null && shouldBlockApp(packageName)) {
                Log.d(TAG, "Detected blocked app in foreground: $packageName")
                blockApp(packageName)
            }
        }
    }
    
    private fun shouldBlockApp(packageName: String): Boolean {
        // Don't block system apps or our own app
        if (packageName == this.packageName || 
            packageName.startsWith("com.android.") ||
            packageName.startsWith("android.") ||
            packageName == "com.android.systemui") {
            return false
        }
        
        return isBlocking && blockedApps.contains(packageName)
    }
    
    private fun blockApp(packageName: String) {
        try {
            // Go to home screen
            val homeIntent = Intent(Intent.ACTION_MAIN)
            homeIntent.addCategory(Intent.CATEGORY_HOME)
            homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(homeIntent)
            
            // Show blocking notification/overlay
            // TODO: Implement blocking overlay or notification
            Log.d(TAG, "Blocked app: $packageName")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error blocking app: ${e.message}")
        }
    }
    
    private fun loadBlockedApps() {
        val blockedAppsString = sharedPreferences.getString("blocked_apps", "")
        blockedApps = if (blockedAppsString.isNullOrEmpty()) {
            emptySet()
        } else {
            blockedAppsString.split(",").toSet()
        }
        
        isBlocking = sharedPreferences.getBoolean("is_blocking", false)
        Log.d(TAG, "Loaded blocked apps: $blockedApps, isBlocking: $isBlocking")
    }
    
    fun updateBlockedApps(apps: Set<String>) {
        blockedApps = apps
        sharedPreferences.edit()
            .putString("blocked_apps", apps.joinToString(","))
            .apply()
        Log.d(TAG, "Updated blocked apps: $blockedApps")
    }
    
    fun setBlockingEnabled(enabled: Boolean) {
        isBlocking = enabled
        sharedPreferences.edit()
            .putBoolean("is_blocking", enabled)
            .apply()
        Log.d(TAG, "Blocking enabled: $enabled")
    }
}