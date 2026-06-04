package com.example.blockit_clone

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import android.net.Uri
import android.content.Intent
import android.app.PendingIntent
import android.content.ComponentName
import android.os.Bundle
import android.view.View
import android.graphics.Color
import es.antonborri.home_widget.HomeWidgetPlugin

class TimerWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_INCREMENT = "com.example.blockit_clone.ACTION_INCREMENT"
        const val ACTION_DECREMENT = "com.example.blockit_clone.ACTION_DECREMENT"
        const val ACTION_TOGGLE_REELS = "com.example.blockit_clone.ACTION_TOGGLE_REELS"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val widgetData = HomeWidgetPlugin.getData(context)
        
        if (intent.action == ACTION_TOGGLE_REELS) {
            val isCurrentlyEnabled = widgetData.getBoolean("widget_reels_blocking_enabled", false)
            val newEnabledState = !isCurrentlyEnabled
            
            // 1. Sync state to home_widget cache
            widgetData.edit().putBoolean("widget_reels_blocking_enabled", newEnabledState).apply()
            
            // 2. Commit immediately to native accessibility service layers
            BlockitAccessibilityService.isReelsBlockingEnabled = newEnabledState
            
            // 3. Force instant re-render loop
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, TimerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            onUpdate(context, appWidgetManager, appWidgetIds, widgetData)
            return
        }
        
        if (intent.action == ACTION_INCREMENT || intent.action == ACTION_DECREMENT) {
            val currentDuration = widgetData.getInt("widget_selected_duration", 15)
            var newDuration = currentDuration

            if (intent.action == ACTION_INCREMENT) {
                newDuration = (currentDuration + 15).coerceIn(15, 180)
            } else if (intent.action == ACTION_DECREMENT) {
                newDuration = (currentDuration - 15).coerceIn(15, 180)
            }

            widgetData.edit().putInt("widget_selected_duration", newDuration).apply()

            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            flutterPrefs.edit().putInt("flutter.last_selected_duration", newDuration).apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, TimerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            onUpdate(context, appWidgetManager, appWidgetIds, widgetData)
            return
        }
        super.onReceive(context, intent)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), widgetData)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    override fun onUpdate(
        context: Context, 
        appWidgetManager: AppWidgetManager, 
        appWidgetIds: IntArray, 
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.timer_widget)

            // Dynamic Sizing Evaluation Logic via Options Framework Bounds
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)

            // FIXED: Identify if the layout has been flattened to a single vertical row cell (2x1)
            val isShortWidget = minHeight < 80

            // Toggle top description padding text out of the view tree completely when cell heights collapse
            views.setViewVisibility(R.id.txt_widget_header, if (isShortWidget) View.GONE else View.VISIBLE)

            // Reveal control switch if stretched and extended beyond its base 2x2 grid cell boundaries
            val showReelsControl = !isShortWidget && (minHeight >= 105 || minWidth >= 170)
            views.setViewVisibility(R.id.layout_widget_reels, if (showReelsControl) View.VISIBLE else View.GONE)

            val minutes = widgetData.getInt("widget_selected_duration", 15)
            views.setTextViewText(R.id.txt_widget_duration, "${minutes}m")

            // Decrement Intent
            val minusIntent = Intent(context, TimerWidgetProvider::class.java).apply { action = ACTION_DECREMENT }
            val minusPendingIntent = PendingIntent.getBroadcast(context, 0, minusIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_widget_minus, minusPendingIntent)

            // Increment Intent
            val plusIntent = Intent(context, TimerWidgetProvider::class.java).apply { action = ACTION_INCREMENT }
            val plusPendingIntent = PendingIntent.getBroadcast(context, 1, plusIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_widget_plus, plusPendingIntent)

            // Reels Toggle Intent Switch Link
            val reelsIntent = Intent(context, TimerWidgetProvider::class.java).apply { action = ACTION_TOGGLE_REELS }
            val reelsPendingIntent = PendingIntent.getBroadcast(context, 2, reelsIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_widget_reels_toggle, reelsPendingIntent)

            // Style state updates inline with selected options settings
            val isReelsEnabled = widgetData.getBoolean("widget_reels_blocking_enabled", false)
            if (isReelsEnabled) {
                views.setTextViewText(R.id.btn_widget_reels_toggle, "ON")
                views.setInt(R.id.btn_widget_reels_toggle, "setBackgroundColor", Color.parseColor("#EED2C2"))
                views.setTextColor(R.id.btn_widget_reels_toggle, Color.parseColor("#000000"))
            } else {
                views.setTextViewText(R.id.btn_widget_reels_toggle, "OFF")
                views.setInt(R.id.btn_widget_reels_toggle, "setBackgroundColor", Color.parseColor("#2A2A2A"))
                views.setTextColor(R.id.btn_widget_reels_toggle, Color.parseColor("#FFFFFF"))
            }

            // Launch Active App Intent Payload
            val playUri = Uri.parse("blockit://start?duration=$minutes")
            val playIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, playUri)
            views.setOnClickPendingIntent(R.id.btn_widget_play, playIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}