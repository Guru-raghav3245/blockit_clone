import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import '../../services/local_storage_service.dart';

/// MANDATORY FIX: This MUST be a standalone top-level global function
/// outside of any class scope so the native background runner can find it.
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;

  // FIXED: Initialize background isolate bindings so plugin communication channel doesn't freeze
  WidgetsFlutterBinding.ensureInitialized();

  final currentDuration = await LocalStorageService.getLastSelectedDuration();
  int newDuration = currentDuration;

  if (uri.host == 'increment') {
    newDuration = (currentDuration + 15).clamp(15, 180);
    await LocalStorageService.saveLastSelectedDuration(newDuration);
    await WidgetHelper.updateWidgetDuration(newDuration);
  } else if (uri.host == 'decrement') {
    newDuration = (currentDuration - 15).clamp(15, 180);
    await LocalStorageService.saveLastSelectedDuration(newDuration);
    await WidgetHelper.updateWidgetDuration(newDuration);
  }
}

class WidgetHelper {
  static const String androidWidgetName = 'TimerWidgetProvider';
  static const String keyDuration = 'widget_selected_duration';

  /// Synchronizes the active application selected duration with the home screen widget view
  static Future<void> updateWidgetDuration(int minutes) async {
    await HomeWidget.saveWidgetData<int>(keyDuration, minutes);

    // FIXED: Explicitly supply the fully qualified package location for specialized device launchers
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      qualifiedAndroidName: 'com.example.blockit_clone.TimerWidgetProvider',
    );
  }
}
