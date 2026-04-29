package com.example.blockit_clone

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Handler
import android.os.Looper
import android.util.Log

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
        if (event == null || !isReelsBlockingEnabled) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName != "com.instagram.android") return

        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) return

        val root = rootInActiveWindow ?: return

        Log.d("Blockit_Debug", "Instagram UI changed")

        if (isInReelsSection(root)) {
            Log.d("Blockit", "Reels section detected → Kicking out")
            performGlobalAction(GLOBAL_ACTION_BACK)
            showReelsBlockedOverlay()
        }
    }

    /** Main detection logic - inspired by successful blockers like ScrollGuard */
    private fun isInReelsSection(root: AccessibilityNodeInfo): Boolean {
        if (root == null) return false

        // 1. Strongest signal: Reels video player is visible
        if (hasReelsVideoPlayer(root)) {
            Log.d("Blockit_Debug", "Detected Reels Video Player")
            return true
        }

        // 2. We're in the dedicated Reels tab/feed (but not just the bottom tab label)
        return hasReelsTabWithContent(root)
    }

    private fun hasReelsVideoPlayer(root: AccessibilityNodeInfo): Boolean {
        return traverse { node ->
            val cls = node.className?.toString() ?: ""
            val id = node.viewIdResourceName ?: ""

            (cls.contains("SurfaceView", true) ||
             cls.contains("TextureView", true) ||
             cls.contains("VideoView", true) ||
             id.contains("reel_viewer", true) ||
             id.contains("clips_viewer", true))
        }
    }

    private fun hasReelsTabWithContent(root: AccessibilityNodeInfo): Boolean {
        return traverse { node ->
            val text = node.text?.toString() ?: ""
            val desc = node.contentDescription?.toString() ?: ""
            val viewId = node.viewIdResourceName ?: ""

            val hasReelsText = text.equals("Reels", ignoreCase = true) || 
                              desc.equals("Reels", ignoreCase = true)

            if (!hasReelsText) return@traverse false

            // Avoid bottom navigation tab
            val isBottomNav = viewId.contains("bottom", true) && viewId.contains("tab", true)

            // Good indicators that we're actually inside Reels content
            val isReelsContent = viewId.contains("reel", true) ||
                                viewId.contains("clips", true) ||
                                viewId.contains("viewer", true) ||
                                node.className?.toString()?.contains("RecyclerView", true) == true

            val shouldBlock = hasReelsText && !isBottomNav && isReelsContent

            if (shouldBlock) {
                Log.d("Blockit_Debug", "Reels tab with content → ViewID: $viewId")
            }
            shouldBlock
        }
    }

    private fun traverse(condition: (AccessibilityNodeInfo) -> Boolean): Boolean {
        return traverseNode(rootInActiveWindow, 0, condition)
    }

    private fun traverseNode(node: AccessibilityNodeInfo?, depth: Int, condition: (AccessibilityNodeInfo) -> Boolean): Boolean {
        if (node == null || depth > 15) return false
        if (condition(node)) return true

        for (i in 0 until node.childCount) {
            if (traverseNode(node.getChild(i), depth + 1, condition)) return true
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

            handler.postDelayed({ removeOverlay() }, 1600)
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
        } catch (e: Exception) {}
    }

    override fun onInterrupt() {}
    override fun onDestroy() {
        removeOverlay()
        instance = null
        super.onDestroy()
    }
}