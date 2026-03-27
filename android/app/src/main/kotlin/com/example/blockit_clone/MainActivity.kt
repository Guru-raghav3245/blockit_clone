package com.example.blockit_clone

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.admin.DevicePolicyManager
import android.content.ComponentName

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.blockit/device_admin"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val dpm = getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, DeviceAdminReceiver::class.java)
            val packageName = packageName

            when (call.method) {
                "startLockTask" -> {
                    val isAdminActive = dpm.isAdminActive(adminComponent)

                    if (isAdminActive) {
                        // Whitelist the app + start Lock Task Mode
                        try {
                            dpm.setLockTaskPackages(adminComponent, arrayOf(packageName))
                        } catch (e: Exception) {
                            // Ignore if already set
                        }
                        startLockTask()
                        result.success(true)
                    } else {
                        result.error("DEVICE_ADMIN_NOT_ACTIVE", "Device Admin is not active", null)
                    }
                }
                "stopLockTask" -> {
                    stopLockTask()
                    result.success(true)
                }
                "isDeviceAdminActive" -> {
                    result.success(dpm.isAdminActive(adminComponent))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}