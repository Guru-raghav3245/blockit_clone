package com.example.blockit_clone

import android.app.Notification
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Base64
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.io.ByteArrayOutputStream

class BlockitNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "BlockitNotif"
        private const val EVENT_CHANNEL = "com.blockit/notifications"

        var isSessionActive = false
            private set

        private var eventSink: EventChannel.EventSink? = null
        private val activeKeys = LinkedHashSet<String>()

        // Buffer events sent while no Flutter sink is attached so nothing is lost
        private val pendingEvents = mutableListOf<Map<String, Any?>>()

        fun setSessionActive(active: Boolean) {
            Log.d(TAG, "setSessionActive=$active")
            isSessionActive = active
            if (!active) {
                activeKeys.clear()
                pendingEvents.clear()
                try {
                    eventSink?.success(mapOf("type" to "sessionEnded"))
                } catch (e: Exception) {
                    Log.e(TAG, "sessionEnded send failed: ${e.message}")
                }
            }
        }

        fun listen(channel: EventChannel) {
            channel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Flutter subscribed; flushing ${pendingEvents.size} pending events")
                    eventSink = events
                    // Flush anything that arrived before the screen subscribed
                    val flush = pendingEvents.toList()
                    pendingEvents.clear()
                    for (event in flush) {
                        try {
                            events?.success(event)
                        } catch (e: Exception) {
                            Log.e(TAG, "flush send failed: ${e.message}")
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListener connected")
        // Replay currently active notifications if a session is running and a sink is ready
        val active = try {
            activeNotifications
        } catch (_: Exception) {
            emptyArray()
        }
        if (isSessionActive) {
            Log.d(TAG, "onListenerConnected: replaying ${active.size} active notifications")
            for (sbn in active) {
                emitNotification(sbn, cancelSystem = true)
            }
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!isSessionActive) return
        Log.d(TAG, "onNotificationPosted: pkg=${sbn.packageName} key=${sbn.key}")
        val key = sbn.key
        activeKeys.add(key)
        emitNotification(sbn, cancelSystem = true)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        val key = sbn.key
        if (activeKeys.remove(key)) {
            deliver(mapOf("type" to "removed", "key" to key))
        }
    }

    private fun emitNotification(sbn: StatusBarNotification, cancelSystem: Boolean) {
        val notification = sbn.notification
        val extras = notification.extras

        val title = extras.getString(Notification.EXTRA_TITLE)
            ?: extras.getCharSequence(Notification.EXTRA_TITLE_BIG)?.toString()
            ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
            ?: ""
        val appPackage = sbn.packageName
        val appName = getAppName(appPackage)
        val appIcon = getAppIcon(appPackage)
        val whenMs = sbn.postTime

        val event = mapOf<String, Any?>(
            "type" to "posted",
            "key" to sbn.key,
            "title" to title,
            "text" to text,
            "subText" to subText,
            "package" to appPackage,
            "appName" to appName,
            "iconBase64" to appIcon,
            "postTime" to whenMs,
        )

        deliver(event)

        if (cancelSystem) {
            try {
                cancelNotification(sbn.key)
            } catch (e: Exception) {
                Log.e(TAG, "cancelNotification failed: ${e.message}")
            }
        }
    }

    private fun getAppIcon(pkg: String): String? {
        return try {
            val pm = packageManager
            val drawable = pm.getApplicationIcon(pkg)
            val bitmap = drawableToBitmap(drawable)
            val iconSize = dp(24)
            val scaled = Bitmap.createScaledBitmap(bitmap, iconSize, iconSize, true)
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.PNG, 100, stream)
            Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
        } catch (_: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = drawable.intrinsicWidth.coerceAtLeast(1)
        val height = drawable.intrinsicHeight.coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    private fun deliver(event: Map<String, Any?>) {
        val sink = eventSink
        if (sink != null) {
            try {
                sink.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "deliver failed: ${e.message}")
                pendingEvents.add(event)
            }
        } else {
            // No screen is listening yet; buffer so it surfaces when it subscribes
            Log.d(TAG, "No sink attached; buffering event")
            pendingEvents.add(event)
        }
    }

    private fun getAppName(pkg: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(pkg, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            pkg
        }
    }
}
