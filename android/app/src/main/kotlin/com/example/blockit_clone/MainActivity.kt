package com.example.blockit_clone

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.provider.Settings
import android.app.admin.DevicePolicyManager
import android.os.PowerManager
import android.os.BatteryManager
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.blockit/device_admin"
    private val BATTERY_STREAM_CHANNEL = "com.blockit/battery_stream"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Existing MethodChannel Configuration
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, DeviceAdminReceiver::class.java)

            when (call.method) {
                "startLockTask" -> {
                    if (dpm.isAdminActive(adminComponent)) {
                        try {
                            dpm.setLockTaskPackages(adminComponent, arrayOf(packageName))
                        } catch (e: Exception) {}
                        startLockTask()
                        BlockitAccessibilityService.isGeneralBlockingEnabled = true
                        result.success(true)
                    } else {
                        result.error("DEVICE_ADMIN_NOT_ACTIVE", "Activate Device Admin first", null)
                    }
                }
                "stopLockTask" -> {
                    BlockitAccessibilityService.isGeneralBlockingEnabled = false
                    stopLockTask()
                    result.success(true)
                }
                "isDeviceAdminActive" -> {
                    result.success(dpm.isAdminActive(adminComponent))
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                "turnOffScreen" -> {
                    if (dpm.isAdminActive(adminComponent)) {
                        dpm.lockNow()
                        result.success(true)
                    } else {
                        result.error("ADMIN_REQUIRED", "Device Admin required", null)
                    }
                }
                "wakeScreen" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    val wakeLock = pm.newWakeLock(
                        PowerManager.FULL_WAKE_LOCK or 
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or 
                        PowerManager.ON_AFTER_RELEASE, 
                        "Blockit:WakeScreen"
                    )
                    wakeLock.acquire(3000)
                    result.success(true)
                }
                "enableReelsBlocking" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    BlockitAccessibilityService.isReelsBlockingEnabled = enable
                    result.success(true)
                }
                "isReelsBlockingEnabled" -> {
                    result.success(BlockitAccessibilityService.isReelsBlockingEnabled)
                }
                else -> result.notImplemented()
            }
        }

        // ================== NEW: DYNAMIC EVENTCHANNEL BATTERY STREAM ==================
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_STREAM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var batteryReceiver: BroadcastReceiver? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    batteryReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent != null) {
                                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                                val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                                val percentage = if (level != -1 && scale != 0) (level * 100 / scale) else -1
                                
                                val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                                val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || 
                                                 status == BatteryManager.BATTERY_STATUS_FULL
                                
                                events?.success(mapOf(
                                    "level" to percentage,
                                    "isCharging" to isCharging
                                ))
                            }
                        }
                    }
                    val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
                    registerReceiver(batteryReceiver, filter)
                }

                override fun onCancel(arguments: Any?) {
                    unregisterReceiver(batteryReceiver)
                    batteryReceiver = null
                }
            }
        )
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == packageName &&
            it.resolveInfo.serviceInfo.name == BlockitAccessibilityService::class.java.name
        }
    }
}