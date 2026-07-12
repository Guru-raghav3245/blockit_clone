import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_task.dart';
import '../services/notification_service.dart';

class TasksProvider extends ChangeNotifier {
  List<RecurringTask> _tasks = [];
  List<TaskRecord> _records = [];

  List<RecurringTask> get tasks => [..._tasks];
  List<TaskRecord> get records => [..._records];

  static const String _tasksKey = 'blockit_recurring_tasks';
  static const String _recordsKey = 'blockit_task_records';

  TasksProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    _tasks = tasksJson.map((t) => RecurringTask.fromJson(t)).toList();

    final recordsJson = prefs.getStringList(_recordsKey) ?? [];
    _records = recordsJson.map((r) => TaskRecord.fromJson(r)).toList();

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final tasksJson = _tasks.map((t) => t.toJson()).toList();
    await prefs.setStringList(_tasksKey, tasksJson);

    final recordsJson = _records.map((r) => r.toJson()).toList();
    await prefs.setStringList(_recordsKey, recordsJson);
  }

  Future<void> addTask(RecurringTask task) async {
    _tasks.add(task);
    await _saveData();
    await NotificationService().scheduleTaskNotifications(task);
    notifyListeners();
  }

  Future<void> updateTask(RecurringTask updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      await _saveData();
      await NotificationService().scheduleTaskNotifications(updatedTask);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    _records.removeWhere((r) => r.taskId == id);
    await _saveData();
    await NotificationService().cancelTaskNotifications(id);
    notifyListeners();
  }

  Future<void> markTaskStatus(String taskId, DateTime date, String status) async {
    // Keep date strictly to year, month, day to avoid duplicates
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Remove existing record for this task on this day
    _records.removeWhere((r) =>
      r.taskId == taskId &&
      r.date.year == normalizedDate.year &&
      r.date.month == normalizedDate.month &&
      r.date.day == normalizedDate.day
    );

    _records.add(TaskRecord(taskId: taskId, date: normalizedDate, status: status));
    await _saveData();
    notifyListeners();
  }

  String? getTaskStatusForDate(String taskId, DateTime date) {
    try {
      final record = _records.firstWhere((r) =>
        r.taskId == taskId &&
        r.date.year == date.year &&
        r.date.month == date.month &&
        r.date.day == date.day
      );
      return record.status;
    } catch (_) {
      return null;
    }
  }
}
