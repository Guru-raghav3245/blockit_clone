import 'dart:convert';
import 'package:flutter/material.dart';

class RecurringTask {
  final String id;
  final String title;
  final TimeOfDay time;
  final List<int> selectedDays; // 1 = Monday, ..., 7 = Sunday

  RecurringTask({
    required this.id,
    required this.title,
    required this.time,
    required this.selectedDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time_hour': time.hour,
      'time_minute': time.minute,
      'selectedDays': selectedDays,
    };
  }

  factory RecurringTask.fromMap(Map<String, dynamic> map) {
    return RecurringTask(
      id: map['id'],
      title: map['title'],
      time: TimeOfDay(hour: map['time_hour'], minute: map['time_minute']),
      selectedDays: List<int>.from(map['selectedDays']),
    );
  }

  String toJson() => json.encode(toMap());

  factory RecurringTask.fromJson(String source) => RecurringTask.fromMap(json.decode(source));

  RecurringTask copyWith({
    String? id,
    String? title,
    TimeOfDay? time,
    List<int>? selectedDays,
  }) {
    return RecurringTask(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }
}

class TaskRecord {
  final String taskId;
  final DateTime date;
  final String status; // 'done', 'not_done'

  TaskRecord({
    required this.taskId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'date': date.toIso8601String(),
      'status': status,
    };
  }

  factory TaskRecord.fromMap(Map<String, dynamic> map) {
    return TaskRecord(
      taskId: map['taskId'],
      date: DateTime.parse(map['date']),
      status: map['status'],
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskRecord.fromJson(String source) => TaskRecord.fromMap(json.decode(source));
}
