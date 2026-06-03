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
            eventTypes =
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags =
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
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

        val className = event.className?.toString() ?: ""
        Log.d("Blockit_Debug", "Instagram UI changed: $className")

        // Optional heuristic: many Reels viewers use names containing Reel/Clips/etc.
        val looksLikeReelsActivity =
            className.contains("Reel", ignoreCase = true) ||
            className.contains("Clip", ignoreCase = true) ||
            className.contains("Viewer", ignoreCase = true)

        // Debounce: avoid spamming back actions on rapid content changes
        val now = System.currentTimeMillis()
        if (now - lastKickoutTime < 1000L) {
            return
        }

        if (isInReelsSection(root, looksLikeReelsActivity)) {
            lastKickoutTime = now
            Log.d("Blockit", "Reels section detected → Kicking out")
            performGlobalAction(GLOBAL_ACTION_BACK)
            showReelsBlockedOverlay()
        }
    }

    /**
     * Main detection logic:
     * - Only true when we're actually in the Reels viewer / feed.
     * - Avoids triggering on generic videos on the home feed or stories.
     */
    private fun isInReelsSection(
        root: AccessibilityNodeInfo,
        looksLikeReelsActivity: Boolean
    ): Boolean {
        // Strongest signal: dedicated Reels viewer UI (video surface inside Reels‑like container)
        if (hasReelsVideoPlayer(root, looksLikeReelsActivity)) {
            Log.d("Blockit_Debug", "Detected Reels Video Player")
            return true
        }

        // Secondary signal: Reels tab selected with content (not just the bottom nav label)
        if (hasReelsTabWithContent(root)) {
            Log.d("Blockit_Debug", "Detected Reels tab with content")
            return true
        }

        return false
    }

    /**
     * Detect a video surface that is specifically part of the Reels viewer.
     * We:
     *  - Look for SurfaceView/TextureView/VideoView.
     *  - Require that some parent in the chain looks Reels‑specific (id/class).
     *  - Optionally combine with the activity name heuristic.
     */
    private fun hasReelsVideoPlayer(
        root: AccessibilityNodeInfo,
        looksLikeReelsActivity: Boolean
    ): Boolean {
        return traverse(root) { node ->
            val cls = node.className?.toString() ?: ""
            val id = node.viewIdResourceName ?: ""

            val looksLikeVideoSurface =
                cls.contains("SurfaceView", ignoreCase = true) ||
                cls.contains("TextureView", ignoreCase = true) ||
                cls.contains("VideoView", ignoreCase = true)

            // If this is not a likely video surface and not directly named for Reels, skip.
            if (!looksLikeVideoSurface &&
                !id.contains("reel_viewer", ignoreCase = true) &&
                !id.contains("clips_viewer", ignoreCase = true)
            ) {
                return@traverse false
            }

            // Walk up ancestors looking for Reels‑specific hints
            var parent = node.parent
            var depth = 0
            var parentMatches = false
            while (parent != null && depth < 6 && !parentMatches) {
                val pid = parent.viewIdResourceName ?: ""
                val pcls = parent.className?.toString() ?: ""

                if (pid.contains("reel", ignoreCase = true) ||
                    pid.contains("clips", ignoreCase = true) ||
                    pid.contains("viewer", ignoreCase = true) ||
                    pcls.contains("Reel", ignoreCase = true) ||
                    pcls.contains("Clips", ignoreCase = true)
                ) {
                    parentMatches = true
                }

                parent = parent.parent
                depth++
            }

            // We only treat this as Reels if:
            //  - The node is a video surface, AND
            //  - It is inside a likely Reels container, AND
            //  - The activity "looks" like Reels (optional but helps reduce feed false‑positives).
            looksLikeVideoSurface && parentMatches && looksLikeReelsActivity
        }
    }

    /**
     * Detect the case where the Reels tab is selected and actual content is shown.
     * This should allow using home, search, messages, profile, etc. freely.
     */
    private fun hasReelsTabWithContent(root: AccessibilityNodeInfo): Boolean {
        return traverse(root) { node ->
            val text = node.text?.toString() ?: ""
            val desc = node.contentDescription?.toString() ?: ""
            val viewId = node.viewIdResourceName ?: ""
            val cls = node.className?.toString() ?: ""

            val hasReelsText =
                text.equals("Reels", ignoreCase = true) ||
                desc.equals("Reels", ignoreCase = true)

            if (!hasReelsText) return@traverse false

            // Likely navigation elements
            val isBottomNavCandidate =
                viewId.contains("bottom", ignoreCase = true) ||
                viewId.contains("tab", ignoreCase = true) ||
                cls.contains("TabLayout", ignoreCase = true) ||
                cls.contains("BottomNavigation", ignoreCase = true)

            // We want the case where Reels is actually selected, i.e. user is in Reels
            val isSelected = node.isSelected

            // Check that there is actual scrollable content associated with this
            // (e.g., a RecyclerView with reels list) somewhere nearby.
            val hasContentAround = hasReelsLikeContentAround(node)

            val shouldBlock = isSelected && hasContentAround && !isBottomNavCandidate

            if (shouldBlock) {
                Log.d(
                    "Blockit_Debug",
                    "Reels tab with content → id=$viewId cls=$cls selected=$isSelected"
                )
            }

            shouldBlock
        }
    }

    /**
     * Look for scrollable/content views related to Reels near the given node
     * (parents or siblings). This reduces false positives where "Reels"
     * label appears but no content is shown yet.
     */
    private fun hasReelsLikeContentAround(node: AccessibilityNodeInfo): Boolean {
        // Check siblings and children of parent for RecyclerView / scrollable content.
        val parent = node.parent ?: return false

        // Check parent itself
        if (parent.isScrollable ||
            parent.className?.toString()?.contains("RecyclerView", ignoreCase = true) == true
        ) {
            return true
        }

        // Check siblings
        for (i in 0 until parent.childCount) {
            val child = parent.getChild(i) ?: continue
            if (child === node) continue

            val ccls = child.className?.toString() ?: ""
            if (child.isScrollable ||
                ccls.contains("RecyclerView", ignoreCase = true) ||
                ccls.contains("ListView", ignoreCase = true) ||
                ccls.contains("GridView", ignoreCase = true)
            ) {
                return true
            }
        }

        return false
    }

    /**
     * Generic DFS traversal starting from a given root node.
     */
    private fun traverse(
        root: AccessibilityNodeInfo?,
        condition: (AccessibilityNodeInfo) -> Boolean
    ): Boolean {
        return traverseNode(root, 0, condition)
    }

    private fun traverseNode(
        node: AccessibilityNodeInfo?,
        depth: Int,
        condition: (AccessibilityNodeInfo) -> Boolean
    ): Boolean {
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
                flags =
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
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
        } catch (_: Exception) {
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        removeOverlay()
        instance = null
        super.onDestroy()
    }
}