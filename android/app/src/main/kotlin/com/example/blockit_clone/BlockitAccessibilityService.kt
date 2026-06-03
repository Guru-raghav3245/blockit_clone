package com.example.blockit_clone

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
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

class BlockitAccessibilityService : AccessibilityService() {

    companion object {
        var isGeneralBlockingEnabled = false
        var isReelsBlockingEnabled = false
        var instance: BlockitAccessibilityService? = null
    }

    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var lastKickoutTime = 0L

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
        if (event == null || !isReelsBlockingEnabled) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName != "com.instagram.android") return

        val root = rootInActiveWindow ?: return

        val now = System.currentTimeMillis()
        if (now - lastKickoutTime < 1200L) {
            return
        }

        // 1. Check if the active viewport layout contains visible Reels layout indicators
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

        // 2. Check if the dedicated bottom Reels tab is actively selected and visible to the user
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

        // 3. Fallback check for localized textual navigation triggers matching selection models
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
            
            showReelsBlockedOverlay()

            // Try programmatically clicking onto the Home feed button
            val redirectedSuccessfully = navigateToHomeTab(root)
            
            // Fallback: If layout covers the navigation bar, execute a single back action to dismiss the layer
            if (!redirectedSuccessfully) {
                Log.d("Blockit", "Home tab not interactable, dropping immersive sheet via system back action")
                performGlobalAction(GLOBAL_ACTION_BACK)
            }
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

            // Button 1 logic: Return to the blockit companion app workspace
            val openAppButton = overlayView?.findViewById<Button>(R.id.btn_open_blockit)
            openAppButton?.setOnClickListener {
                Log.d("Blockit", "Overlay action button clicked -> Routing back to host application")
                removeOverlay()

                val launchIntent = packageManager.getLaunchIntentForPackage("com.example.blockit_clone")
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(launchIntent)
                }
            }

            // Button 2 logic: Close modal window layout exclusively 
            val dismissButton = overlayView?.findViewById<Button>(R.id.btn_dismiss_overlay)
            dismissButton?.setOnClickListener {
                Log.d("Blockit", "Overlay dismiss button clicked -> Cleaning up layout overlay")
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
            // Note: handler.postDelayed timer removed completely as requested. Modal will persist until explicitly closed.

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

    override fun onInterrupt() {}

    override fun onDestroy() {
        removeOverlay()
        instance = null
        super.onDestroy()
    }
}