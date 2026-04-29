package com.example.blockit_clone

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.TextView
import android.os.Handler
import android.os.Looper

class BlockitAccessibilityService : AccessibilityService() {

    companion object {
        var isGeneralBlockingEnabled = false
        var isReelsBlockingEnabled = false
        var instance: BlockitAccessibilityService? = null
    }

    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        instance = this

        serviceInfo = serviceInfo.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return

        // Instagram Reels Blocking
        if (isReelsBlockingEnabled && packageName == "com.instagram.android") {
            when (event.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {

                    val rootNode = rootInActiveWindow ?: return

                    if (isReelsDetected(rootNode)) {
                        performGlobalAction(GLOBAL_ACTION_BACK)
                        showReelsBlockedOverlay()
                    }
                }
            }
        }
    }

    private fun isReelsDetected(root: AccessibilityNodeInfo): Boolean {
        if (root == null) return false
        if (containsReelsKeyword(root)) return true
        return traverseForReels(root, 0)
    }

    private fun containsReelsKeyword(node: AccessibilityNodeInfo): Boolean {
        val text = node.text?.toString() ?: ""
        val contentDesc = node.contentDescription?.toString() ?: ""
        val className = node.className?.toString() ?: ""
        val viewId = node.viewIdResourceName ?: ""

        val keywords = listOf("Reels", "Reel", "Clips", "reel", "clips")

        return keywords.any { kw ->
            text.contains(kw, ignoreCase = true) ||
            contentDesc.contains(kw, ignoreCase = true) ||
            className.contains(kw, ignoreCase = true) ||
            viewId.contains(kw, ignoreCase = true)
        }
    }

    private fun traverseForReels(node: AccessibilityNodeInfo?, depth: Int): Boolean {
        if (node == null || depth > 8) return false
        if (containsReelsKeyword(node)) return true

        for (i in 0 until node.childCount) {
            if (traverseForReels(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    /**
     * Shows a beautiful temporary overlay when Reels is blocked
     */
    private fun showReelsBlockedOverlay() {
        try {
            // Remove existing overlay if any
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

            val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
            windowManager.addView(overlayView, params)

            // Auto dismiss after 1.8 seconds
            handler.postDelayed({
                removeOverlay()
            }, 1800)

        } catch (e: Exception) {
            // Fallback if overlay fails
            e.printStackTrace()
        }
    }

    private fun removeOverlay() {
        try {
            overlayView?.let {
                val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
                windowManager.removeView(it)
                overlayView = null
            }
        } catch (e: Exception) {}
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        removeOverlay()
        instance = null
        super.onDestroy()
    }
}