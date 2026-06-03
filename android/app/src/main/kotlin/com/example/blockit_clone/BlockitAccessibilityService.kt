package com.example.blockit_clone

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
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

        val className = event.className?.toString() ?: ""
        val root = rootInActiveWindow ?: return

        val now = System.currentTimeMillis()
        if (now - lastKickoutTime < 1200L) {
            return
        }

        // 1. Check if explicit structural Reels elements are visible on screen
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

        // 2. Check if the Reels Tab button is actively selected AND visible to the user
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

        // 3. Fallback textual validation for the bottom navigation bar selection states
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

        // Trigger restriction protocol if any active validation matches
        if (hasVisibleClipsLayout || isReelsTabSelected || isReelsTextTabActive) {
            lastKickoutTime = now
            Log.d("Blockit", "Active Reels signature verified -> Redirecting to home feed")
            
            showReelsBlockedOverlay()

            // Attempt to click the Home tab container automatically
            val redirectedSuccessfully = navigateToHomeTab(root)
            
            // If the Home button is hidden or non-interactive (e.g. immersive player layer), use BACK fallback
            if (!redirectedSuccessfully) {
                Log.d("Blockit", "Home tab not clickable in viewport, executing layer dismissal fallback")
                performGlobalAction(GLOBAL_ACTION_BACK)
            }
        }
    }

    /**
     * Finds and click the Home feed tab view components programmatically
     */
    private fun navigateToHomeTab(root: AccessibilityNodeInfo): Boolean {
        // Try locating via common Instagram navigation view resource identifiers
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

        // Fallback search via text localization strings
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

    /**
     * Traverses upward through target view parent nodes to ensure a click event registers correctly
     */
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

            val params = WindowManager.LayoutParams().apply {
                type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                format = PixelFormat.TRANSLUCENT
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                width = WindowManager.LayoutParams.MATCH_PARENT
                height = WindowManager.LayoutParams.MATCH_PARENT
                gravity = Gravity.CENTER
            }

            (getSystemService(WINDOW_SERVICE) as WindowManager).addView(overlayView, params)
            handler.postDelayed({ removeOverlay() }, 1500)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun removeOverlay() {
        try {
            overlayView?.let {
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