import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/tasks_provider.dart';
import '../../models/recurring_task.dart';

class TaskEditDialog extends StatefulWidget {
  final RecurringTask? task;

  const TaskEditDialog({super.key, this.task});

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  late TextEditingController _titleController;
  late TimeOfDay _selectedTime;
  final List<int> _selectedDays = [];

  final List<Map<String, dynamic>> _daysOfWeek = [
    {'name': 'M', 'value': 1},
    {'name': 'T', 'value': 2},
    {'name': 'W', 'value': 3},
    {'name': 'T', 'value': 4},
    {'name': 'F', 'value': 5},
    {'name': 'S', 'value': 6},
    {'name': 'S', 'value': 7},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _selectedTime = widget.task?.time ?? TimeOfDay.now();
    if (widget.task != null) {
      _selectedDays.addAll(widget.task!.selectedDays);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleDay(int dayValue) {
    setState(() {
      if (_selectedDays.contains(dayValue)) {
        _selectedDays.remove(dayValue);
      } else {
        _selectedDays.add(dayValue);
      }
    });
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final provider = context.read<TasksProvider>();

    if (widget.task != null) {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text.trim(),
        time: _selectedTime,
        selectedDays: _selectedDays,
      );
      provider.updateTask(updatedTask);
    } else {
      final newTask = RecurringTask(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        time: _selectedTime,
        selectedDays: _selectedDays,
      );
      provider.addTask(newTask);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppConstants.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.task == null ? 'Add Task' : 'Edit Task',
        style: const TextStyle(
          color: AppConstants.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppConstants.textPrimary),
              decoration: InputDecoration(
                labelText: 'Task Title',
                labelStyle: const TextStyle(color: AppConstants.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppConstants.borderColor),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppConstants.primaryAccent),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Time:',
                  style: TextStyle(color: AppConstants.textPrimary, fontSize: 16),
                ),
                TextButton(
                  onPressed: _selectTime,
                  child: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      color: AppConstants.primaryAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Repeat on:',
              style: TextStyle(color: AppConstants.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysOfWeek.map((day) {
                final isSelected = _selectedDays.contains(day['value']);
                return GestureDetector(
                  onTap: () => _toggleDay(day['value']),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? AppConstants.primaryAccent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppConstants.primaryAccent : AppConstants.borderColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        day['name'],
                        style: TextStyle(
                          color: isSelected ? AppConstants.textDark : AppConstants.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppConstants.textMuted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryAccent,
            foregroundColor: AppConstants.textDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _saveTask,
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
