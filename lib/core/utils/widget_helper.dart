import 'package:home_widget/home_widget.dart';

/// Managed entirely natively in Kotlin to provide sub-millisecond updates
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  // Left active as an open hook for interactive updates if expanding features later
  return;
}

class WidgetHelper {
  static const String androidWidgetName = 'TimerWidgetProvider';
  static const String keyDuration = 'widget_selected_duration';

  /// Synchronizes the active application selected duration with the home screen widget view
  static Future<void> updateWidgetDuration(int minutes) async {
    await HomeWidget.saveWidgetData<int>(keyDuration, minutes);
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      qualifiedAndroidName: 'com.example.blockit_clone.TimerWidgetProvider',
    );
  }
}
