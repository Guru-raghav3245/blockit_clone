import 'package:home_widget/home_widget.dart';
import '../../services/local_storage_service.dart';

class WidgetHelper {
  static const String androidWidgetName = 'TimerWidgetProvider';
  static const String keyDuration = 'widget_selected_duration';

  /// Synchronizes the active application selected duration with the home screen widget view
  static Future<void> updateWidgetDuration(int minutes) async {
    await HomeWidget.saveWidgetData<int>(keyDuration, minutes);
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
    );
  }

  /// Background callback loop triggered when step adjustments (+/- buttons) are tapped on the widget
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri == null) return;

    final currentDuration = await LocalStorageService.getLastSelectedDuration();
    int newDuration = currentDuration;

    if (uri.host == 'increment') {
      newDuration = (currentDuration + 15).clamp(15, 180);
      await LocalStorageService.saveLastSelectedDuration(newDuration);
      await updateWidgetDuration(newDuration);
    } else if (uri.host == 'decrement') {
      newDuration = (currentDuration - 15).clamp(15, 180);
      await LocalStorageService.saveLastSelectedDuration(newDuration);
      await updateWidgetDuration(newDuration);
    }
  }
}