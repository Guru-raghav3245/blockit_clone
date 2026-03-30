package com.example.blockit_clone

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.app.admin.DevicePolicyManager
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.blockit/device_admin"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val dpm = getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, DeviceAdminReceiver::class.java)

            when (call.method) {
                "startLockTask" -> {
                    if (dpm.isAdminActive(adminComponent)) {
                        try {
                            dpm.setLockTaskPackages(adminComponent, arrayOf(packageName))
                        } catch (e: Exception) {}
                        startLockTask()
                        // Enable accessibility blocking
                        BlockitAccessibilityService.isBlockingEnabled = true
                        result.success(true)
                    } else {
                        result.error("DEVICE_ADMIN_NOT_ACTIVE", "Please activate Device Admin first", null)
                    }
                }
                "stopLockTask" -> {
                    // Disable accessibility blocking FIRST
                    BlockitAccessibilityService.isBlockingEnabled = false
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
                // NEW: Force the screen to sleep
                "turnOffScreen" -> {
                    if (dpm.isAdminActive(adminComponent)) {
                        try {
                            dpm.lockNow()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("LOCK_FAILED", "Could not turn off screen: ${e.message}", null)
                        }
                    } else {
                        result.error("DEVICE_ADMIN_NOT_ACTIVE", "Device Admin is required to lock the screen", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == packageName &&
            it.resolveInfo.serviceInfo.name == BlockitAccessibilityService::class.java.name
        }
    }
}