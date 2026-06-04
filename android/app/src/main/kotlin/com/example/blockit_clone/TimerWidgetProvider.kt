package com.example.blockit_clone

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import android.net.Uri

// Changed base inheritance class to HomeWidgetProvider
class TimerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context, 
        appWidgetManager: AppWidgetManager, 
        appWidgetIds: IntArray, 
        widgetData: SharedPreferences // Receives pre-configured storage container directly
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.timer_widget)

            // Extract the selection state variable using the plugin data channel map directly
            val minutes = widgetData.getInt("widget_selected_duration", 15)
            
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