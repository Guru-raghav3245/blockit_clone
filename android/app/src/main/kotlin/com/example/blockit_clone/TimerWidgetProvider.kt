package com.example.blockit_clone

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import android.net.Uri

class TimerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.timer_widget)

            // Extract cached state variables written by SharedPreferences
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val minutes = prefs.getInt("widget_selected_duration", 15)
            
            views.setTextViewText(R.id.txt_widget_duration, "${minutes}m")

            // Setup Decrement Background Intent Bridge
            val minusUri = Uri.parse("blockit://decrement")
            val minusIntent = HomeWidgetBackgroundIntent.getBroadcast(context, minusUri)
            views.setOnClickPendingIntent(R.id.btn_widget_minus, minusIntent)

            // Setup Increment Background Intent Bridge
            val plusUri = Uri.parse("blockit://increment")
            val plusIntent = HomeWidgetBackgroundIntent.getBroadcast(context, plusUri)
            views.setOnClickPendingIntent(R.id.btn_widget_plus, plusIntent)

            // Setup Play Click Action to launch the full app with deep link data payload
            val playUri = Uri.parse("blockit://start")
            val playIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, playUri)
            views.setOnClickPendingIntent(R.id.btn_widget_play, playIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}