package com.mindfence.app.mind_fence

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import android.util.Log
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.app.ActivityManager

class BlockingService : Service() {
    
    private val TAG = "MindFenceBlockingService"
    private val CHANNEL_ID = "blocking_service_channel"
    private val NOTIFICATION_ID = 1
    private lateinit var sharedPreferences: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private val monitorInterval = 1000L // Check every second
    private var isServiceRunning = false
    private var blockedApps: Set<String> = emptySet()
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "BlockingService created")
        
        sharedPreferences = getSharedPreferences("mind_fence_prefs", Context.MODE_PRIVATE)
        loadBlockedApps()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "BlockingService started")
        
        when (intent?.action) {
            ACTION_START_BLOCKING -> {
                startBlocking()
            }
            ACTION_STOP_BLOCKING -> {
                stopBlocking()
            }
            ACTION_UPDATE_BLOCKED_APPS -> {
                val apps = intent.getStringArrayListExtra(EXTRA_BLOCKED_APPS)
                updateBlockedApps(apps?.toSet() ?: emptySet())
            }
        }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "BlockingService destroyed")
        stopBlocking()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mind Fence Blocking Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the app blocking service running"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Mind Fence Active")
        .setContentText("Blocking distracting apps")
        .setSmallIcon(R.drawable.ic_notification)
        .setOngoing(true)
        .setContentIntent(createPendingIntent())
        .build()
    
    private fun createPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        return PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
    
    private fun startBlocking() {
        if (!isServiceRunning) {
            isServiceRunning = true
            Log.d(TAG, "Starting app blocking")
            startMonitoring()
        }
    }
    
    private fun stopBlocking() {
        if (isServiceRunning) {
            isServiceRunning = false
            Log.d(TAG, "Stopping app blocking")
            stopMonitoring()
        }
    }
    
    private fun startMonitoring() {
        val monitoringRunnable = object : Runnable {
            override fun run() {
                if (isServiceRunning) {
                    checkForegroundApp()
                    handler.postDelayed(this, monitorInterval)
                }
            }
        }
        handler.post(monitoringRunnable)
    }
    
    private fun stopMonitoring() {
        handler.removeCallbacksAndMessages(null)
    }
    
    private fun checkForegroundApp() {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningTasks = activityManager.getRunningTasks(1)
            
            if (runningTasks.isNotEmpty()) {
                val topActivity = runningTasks[0].topActivity
                val packageName = topActivity?.packageName
                
                if (packageName != null && shouldBlockApp(packageName)) {
                    Log.d(TAG, "Blocking app: $packageName")
                    blockApp(packageName)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking foreground app: ${e.message}")
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
        
        return blockedApps.contains(packageName)
    }
    
    private fun blockApp(packageName: String) {
        try {
            // Go to home screen
            val homeIntent = Intent(Intent.ACTION_MAIN)
            homeIntent.addCategory(Intent.CATEGORY_HOME)
            homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(homeIntent)
            
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
        Log.d(TAG, "Loaded blocked apps: $blockedApps")
    }
    
    private fun updateBlockedApps(apps: Set<String>) {
        blockedApps = apps
        sharedPreferences.edit()
            .putString("blocked_apps", apps.joinToString(","))
            .apply()
        Log.d(TAG, "Updated blocked apps: $blockedApps")
    }
    
    companion object {
        const val ACTION_START_BLOCKING = "com.mindfence.app.START_BLOCKING"
        const val ACTION_STOP_BLOCKING = "com.mindfence.app.STOP_BLOCKING"
        const val ACTION_UPDATE_BLOCKED_APPS = "com.mindfence.app.UPDATE_BLOCKED_APPS"
        const val EXTRA_BLOCKED_APPS = "blocked_apps"
        
        fun startBlocking(context: Context, blockedApps: List<String>) {
            val intent = Intent(context, BlockingService::class.java)
            intent.action = ACTION_START_BLOCKING
            intent.putStringArrayListExtra(EXTRA_BLOCKED_APPS, ArrayList(blockedApps))
            context.startForegroundService(intent)
        }
        
        fun stopBlocking(context: Context) {
            val intent = Intent(context, BlockingService::class.java)
            intent.action = ACTION_STOP_BLOCKING
            context.startService(intent)
        }
        
        fun updateBlockedApps(context: Context, blockedApps: List<String>) {
            val intent = Intent(context, BlockingService::class.java)
            intent.action = ACTION_UPDATE_BLOCKED_APPS
            intent.putStringArrayListExtra(EXTRA_BLOCKED_APPS, ArrayList(blockedApps))
            context.startService(intent)
        }
    }
}