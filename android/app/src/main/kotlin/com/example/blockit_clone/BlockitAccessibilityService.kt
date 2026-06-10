package com.example.blockit_clone

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import org.json.JSONArray
import org.json.JSONObject
import es.antonborri.home_widget.HomeWidgetPlugin

class BlockitAccessibilityService : AccessibilityService() {

    companion object {
        var isGeneralBlockingEnabled = false
        var isReelsBlockingEnabled = false
        var instance: BlockitAccessibilityService? = null
    }

    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var lastKickoutTime = 0L
    
    // Lifecycle properties to capture dynamic focus duration
    private var instagramSessionStart = 0L

    override fun onServiceConnected() {
        instance = this
        serviceInfo = serviceInfo.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                         AccessibilityEvent.TYPE_VIEW_FOCUSED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 20
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        
        // 1. Session tracking allocation architecture
        if (packageName == "com.instagram.android") {
            if (instagramSessionStart == 0L) {
                instagramSessionStart = System.currentTimeMillis()
            }
        } else {
            // User navigated completely away from Instagram -> Flush clean accumulated duration
            finalizeCleanInstagramSession()
        }

        if (!isReelsBlockingEnabled || packageName != "com.instagram.android") return

        val root = rootInActiveWindow ?: return
        val now = System.currentTimeMillis()
        if (now - lastKickoutTime < 1200L) {
            return
        }

        var hasVisibleClipsLayout = false
        val clipsLayoutNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/root_clips_layout")
        if (!clipsLayoutNodes.isNullOrEmpty()) {
            for (node in clipsLayoutNodes) {
                if (node.isVisibleToUser) {
                    hasVisibleClipsLayout = true
                    break
                }
            }
        }

        var isReelsTabSelected = false
        val clipsTabNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/clips_tab")
        if (!clipsTabNodes.isNullOrEmpty()) {
            for (node in clipsTabNodes) {
                if (node.isSelected && node.isVisibleToUser) {
                    isReelsTabSelected = true
                    break
                }
            }
        }

        var isReelsTextTabActive = false
        val reelsTextNodes = root.findAccessibilityNodeInfosByText("Reels")
        if (!reelsTextNodes.isNullOrEmpty()) {
            for (node in reelsTextNodes) {
                if (node.isSelected && node.isVisibleToUser) {
                    isReelsTextTabActive = true
                    break
                }
            }
        }

        // Trigger safe kickout if any visible Reels signature matches
        if (hasVisibleClipsLayout || isReelsTabSelected || isReelsTextTabActive) {
            lastKickoutTime = now
            Log.d("Blockit", "Active Reels signature verified -> Executing Home Tab redirection")
            
            // Intercepted by a Reel -> Finalize and save clean time accumulated up to this exact second
            finalizeCleanInstagramSession()

            showReelsBlockedOverlay()
            val redirectedSuccessfully = navigateToHomeTab(root)
            
            if (!redirectedSuccessfully) {
                Log.d("Blockit", "Home tab not interactable, dropping immersive sheet via system back action")
                performGlobalAction(GLOBAL_ACTION_BACK)
            }
        }
    }

    private fun finalizeCleanInstagramSession() {
        if (instagramSessionStart == 0L) return
        
        val elapsedMs = System.currentTimeMillis() - instagramSessionStart
        instagramSessionStart = 0L // Reset immediately to prevent looping conditions
        
        // Log clean sessions if they lasted for longer than 10 seconds to screen out accidental launches
        if (elapsedMs >= 10000L) {
            val minutesEarned = (elapsedMs / 1000L / 60L).toInt().coerceAtLeast(1)
            commitCleanTimeToBuffer(minutesEarned)
        }
    }

    private fun commitCleanTimeToBuffer(minutes: Int) {
        try {
            val widgetData = HomeWidgetPlugin.getData(applicationContext)
            val currentBufferJson = widgetData.getString("native_reels_free_time_buffer", "[]") ?: "[]"
            val jsonArray = JSONArray(currentBufferJson)
            
            val recordObject = JSONObject().apply {
                put("durationMinutes", minutes)
                put("timestamp", System.currentTimeMillis())
            }
            jsonArray.put(recordObject)
            
            widgetData.edit().putString("native_reels_free_time_buffer", jsonArray.toString()).apply()
            Log.d("Blockit", "Successfully cached $minutes clean reels-free minutes to disk buffer")
        } catch (e: Exception) {
            Log.e("Blockit", "Failed to compile native time buffer map array: ${e.message}")
        }
    }

    private fun navigateToHomeTab(root: AccessibilityNodeInfo): Boolean {
        val homeViewIds = arrayOf(
            "com.instagram.android:id/feed_tab",
            "com.instagram.android:id/tab_home",
            "com.instagram.android:id/home_tab"
        )
        for (id in homeViewIds) {
            val nodes = root.findAccessibilityNodeInfosByViewId(id)
            if (!nodes.isNullOrEmpty()) {
                for (node in nodes) {
                    if (node.isVisibleToUser && performClick(node)) {
                        // Restart clean tracking loop since they are safely back on the home feed
                        instagramSessionStart = System.currentTimeMillis()
                        return true
                    }
                }
            }
        }

        val homeTextLabels = arrayOf("Home", "Feed")
        for (label in homeTextLabels) {
            val nodes = root.findAccessibilityNodeInfosByText(label)
            if (!nodes.isNullOrEmpty()) {
                for (node in nodes) {
                    if (node.isVisibleToUser && performClick(node)) {
                        instagramSessionStart = System.currentTimeMillis()
                        return true
                    }
                }
            }
        }
        return false
    }

    private fun performClick(node: AccessibilityNodeInfo?): Boolean {
        var current = node
        while (current != null) {
            if (current.isClickable) {
                return current.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            }
            current = current.parent
        }
        return false
    }

    private fun showReelsBlockedOverlay() {
        try {
            removeOverlay()
            val inflater = LayoutInflater.from(this)
            overlayView = inflater.inflate(R.layout.reels_blocked_overlay, null)

            val openAppButton = overlayView?.findViewById<Button>(R.id.btn_open_blockit)
            openAppButton?.setOnClickListener {
                removeOverlay()
                val launchIntent = packageManager.getLaunchIntentForPackage("com.example.blockit_clone")
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(launchIntent)
                }
            }

            val dismissButton = overlayView?.findViewById<Button>(R.id.btn_dismiss_overlay)
            dismissButton?.setOnClickListener {
                removeOverlay()
            }

            val params = WindowManager.LayoutParams().apply {
                type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                format = PixelFormat.TRANSLUCENT
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                width = WindowManager.LayoutParams.MATCH_PARENT
                height = WindowManager.LayoutParams.MATCH_PARENT
                gravity = Gravity.CENTER
            }
            (getSystemService(WINDOW_SERVICE) as WindowManager).addView(overlayView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun removeOverlay() {
        try {
            overlayView?.let {
                it.findViewById<Button>(R.id.btn_open_blockit)?.setOnClickListener(null)
                it.findViewById<Button>(R.id.btn_dismiss_overlay)?.setOnClickListener(null)
                (getSystemService(WINDOW_SERVICE) as WindowManager).removeView(it)
                overlayView = null
            }
        } catch (_: Exception) {}
    }

    override fun onInterrupt() {
        finalizeCleanInstagramSession()
    }

    override fun onDestroy() {
        finalizeCleanInstagramSession()
        removeOverlay()
        instance = null
        super.onDestroy()
    }
}