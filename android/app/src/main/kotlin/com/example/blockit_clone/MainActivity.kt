package com.example.blockit_clone

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.app.admin.DevicePolicyManager
import android.os.PowerManager
import android.os.BatteryManager
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.blockit/device_admin"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

                // ================== FIXED: BATTERY LEVEL & STATUS RETRIEVAL ==================
                "getBatteryInfo" -> {
                    val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                    val percentage = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                    val status = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_STATUS)
                    val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
                    
                    result.success(mapOf(
                        "level" to percentage,
                        "isCharging" to isCharging
                    ))
                }

                // ================== NEW: REELS BLOCKING ==================
                "enableReelsBlocking" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    BlockitAccessibilityService.isReelsBlockingEnabled = enable
                    result.success(true)
                }
                "isReelsBlockingEnabled" -> {
                    result.success(BlockitAccessibilityService.isReelsBlockingEnabled)
                }
                // =========================================================

                else -> result.notImplemented()
            }
        }
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