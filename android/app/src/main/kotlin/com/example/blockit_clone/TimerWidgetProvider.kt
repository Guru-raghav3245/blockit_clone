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
import es.antonborri.home_widget.HomeWidgetPlugin

class TimerWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_INCREMENT = "com.example.blockit_clone.ACTION_INCREMENT"
        const val ACTION_DECREMENT = "com.example.blockit_clone.ACTION_DECREMENT"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_INCREMENT || intent.action == ACTION_DECREMENT) {
            // Retrieve shared home_widget storage layout natively
            val widgetData = HomeWidgetPlugin.getData(context)
            val currentDuration = widgetData.getInt("widget_selected_duration", 15)
            var newDuration = currentDuration

            if (intent.action == ACTION_INCREMENT) {
                newDuration = (currentDuration + 15).coerceIn(15, 180)
            } else if (intent.action == ACTION_DECREMENT) {
                newDuration = (currentDuration - 15).coerceIn(15, 180)
            }

            // 1. Update native widget view cache
            widgetData.edit().putInt("widget_selected_duration", newDuration).apply()

            // 2. OPTIMISTIC SYNC: Write instantly to Flutter's expected SharedPreferences namespace
            // This guarantees Flutter matches the widget instantly whenever the app opens
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            flutterPrefs.edit().putInt("flutter.last_selected_duration", newDuration).apply()

            // 3. Force re-render all instances of the home widget instantly
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, TimerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            onUpdate(context, appWidgetManager, appWidgetIds, widgetData)
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context, 
        appWidgetManager: AppWidgetManager, 
        appWidgetIds: IntArray, 
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.timer_widget)

            val minutes = widgetData.getInt("widget_selected_duration", 15)
            views.setTextViewText(R.id.txt_widget_duration, "${minutes}m")

            // Setup Decrement Native Intent (Bypasses background worker delay)
            val minusIntent = Intent(context, TimerWidgetProvider::class.java).apply {
                action = ACTION_DECREMENT
            }
            val minusPendingIntent = PendingIntent.getBroadcast(
                context, 0, minusIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_widget_minus, minusPendingIntent)

            // Setup Increment Native Intent (Bypasses background worker delay)
            val plusIntent = Intent(context, TimerWidgetProvider::class.java).apply {
                action = ACTION_INCREMENT
            }
            val plusPendingIntent = PendingIntent.getBroadcast(
                context, 1, plusIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_widget_plus, plusPendingIntent)

            // Setup Play Click Action containing the exact selected duration
            val playUri = Uri.parse("blockit://start?duration=$minutes")
            val playIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, playUri)
            views.setOnClickPendingIntent(R.id.btn_widget_play, playIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}