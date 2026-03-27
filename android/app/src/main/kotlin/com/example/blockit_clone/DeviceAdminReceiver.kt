package com.example.blockit_clone   // ← CHANGE THIS to match your actual package name

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class DeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        Toast.makeText(context, "✅ Device Admin activated – full lockdown ready", Toast.LENGTH_SHORT).show()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Toast.makeText(context, "❌ Device Admin disabled", Toast.LENGTH_SHORT).show()
    }

    override fun onPasswordChanged(context: Context, intent: Intent) {}
    override fun onPasswordFailed(context: Context, intent: Intent) {}
    override fun onPasswordSucceeded(context: Context, intent: Intent) {}
}