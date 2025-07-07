package com.mindfence.app.mind_fence

import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.util.concurrent.atomic.AtomicBoolean

class VpnService : VpnService() {
    
    private val TAG = "MindFenceVpnService"
    private var vpnInterface: ParcelFileDescriptor? = null
    private var isRunning = AtomicBoolean(false)
    private var inputStream: FileInputStream? = null
    private var outputStream: FileOutputStream? = null
    private var blockedDomains: Set<String> = setOf(
        "facebook.com", "instagram.com", "twitter.com", "youtube.com",
        "tiktok.com", "snapchat.com", "reddit.com", "linkedin.com"
    )
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "VPN Service started")
        
        when (intent?.action) {
            ACTION_START_VPN -> {
                startVpn()
            }
            ACTION_STOP_VPN -> {
                stopVpn()
            }
            ACTION_UPDATE_BLOCKED_DOMAINS -> {
                val domains = intent.getStringArrayListExtra(EXTRA_BLOCKED_DOMAINS)
                updateBlockedDomains(domains?.toSet() ?: emptySet())
            }
        }
        
        return START_STICKY
    }
    
    private fun startVpn() {
        if (isRunning.get()) {
            Log.d(TAG, "VPN already running")
            return
        }
        
        try {
            // Create VPN interface
            val builder = Builder()
                .setSession("Mind Fence VPN")
                .addAddress("10.0.0.1", 24)
                .addRoute("0.0.0.0", 0)
                .addDnsServer("8.8.8.8")
                .addDnsServer("8.8.4.4")
                .setBlocking(true)
            
            // Set up the VPN interface
            vpnInterface = builder.establish()
            
            if (vpnInterface != null) {
                isRunning.set(true)
                Log.d(TAG, "VPN interface established")
                
                // Start packet processing in background thread
                Thread {
                    processPackets()
                }.start()
            } else {
                Log.e(TAG, "Failed to establish VPN interface")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting VPN: ${e.message}")
            isRunning.set(false)
        }
    }
    
    private fun stopVpn() {
        if (!isRunning.get()) {
            Log.d(TAG, "VPN not running")
            return
        }
        
        isRunning.set(false)
        
        try {
            inputStream?.close()
            outputStream?.close()
            vpnInterface?.close()
            
            Log.d(TAG, "VPN stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping VPN: ${e.message}")
        }
    }
    
    private fun processPackets() {
        Log.d(TAG, "Starting packet processing")
        
        vpnInterface?.let { vpnInterface ->
            inputStream = FileInputStream(vpnInterface.fileDescriptor)
            outputStream = FileOutputStream(vpnInterface.fileDescriptor)
            
            val buffer = ByteBuffer.allocate(32767)
            
            while (isRunning.get()) {
                try {
                    val inputChannel = inputStream!!.channel
                    val outputChannel = outputStream!!.channel
                    
                    // Read packet from VPN interface
                    buffer.clear()
                    val length = inputChannel.read(buffer)
                    
                    if (length > 0) {
                        buffer.flip()
                        
                        // Process the packet
                        val shouldBlock = processPacket(buffer)
                        
                        if (!shouldBlock) {
                            // Forward packet if not blocked
                            buffer.flip()
                            outputChannel.write(buffer)
                        }
                    }
                } catch (e: Exception) {
                    if (isRunning.get()) {
                        Log.e(TAG, "Error processing packet: ${e.message}")
                    }
                }
            }
        }
    }
    
    private fun processPacket(buffer: ByteBuffer): Boolean {
        try {
            // Simple packet inspection
            val packetData = ByteArray(buffer.remaining())
            buffer.get(packetData)
            
            val packetString = String(packetData)
            
            // Check if packet contains blocked domains
            for (domain in blockedDomains) {
                if (packetString.contains(domain, ignoreCase = true)) {
                    Log.d(TAG, "Blocking packet containing: $domain")
                    return true
                }
            }
            
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error processing packet: ${e.message}")
            return false
        }
    }
    
    private fun updateBlockedDomains(domains: Set<String>) {
        blockedDomains = domains
        Log.d(TAG, "Updated blocked domains: $blockedDomains")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "VPN Service destroyed")
        stopVpn()
    }
    
    companion object {
        const val ACTION_START_VPN = "com.mindfence.app.START_VPN"
        const val ACTION_STOP_VPN = "com.mindfence.app.STOP_VPN"
        const val ACTION_UPDATE_BLOCKED_DOMAINS = "com.mindfence.app.UPDATE_BLOCKED_DOMAINS"
        const val EXTRA_BLOCKED_DOMAINS = "blocked_domains"
        
        fun startVpn(context: android.content.Context, blockedDomains: List<String>) {
            val intent = Intent(context, VpnService::class.java)
            intent.action = ACTION_START_VPN
            intent.putStringArrayListExtra(EXTRA_BLOCKED_DOMAINS, ArrayList(blockedDomains))
            context.startService(intent)
        }
        
        fun stopVpn(context: android.content.Context) {
            val intent = Intent(context, VpnService::class.java)
            intent.action = ACTION_STOP_VPN
            context.startService(intent)
        }
        
        fun updateBlockedDomains(context: android.content.Context, blockedDomains: List<String>) {
            val intent = Intent(context, VpnService::class.java)
            intent.action = ACTION_UPDATE_BLOCKED_DOMAINS
            intent.putStringArrayListExtra(EXTRA_BLOCKED_DOMAINS, ArrayList(blockedDomains))
            context.startService(intent)
        }
    }
}