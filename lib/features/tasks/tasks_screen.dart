import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/tasks_provider.dart';
import 'task_edit_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        title: const Text(
          'Tasks',
          style: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryAccent,
          labelColor: AppConstants.primaryAccent,
          unselectedLabelColor: AppConstants.textMuted,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'All Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TodayTasksView(),
          _AllTasksView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.primaryAccent,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const TaskEditDialog(),
          );
        },
        child: const Icon(Icons.add, color: AppConstants.textDark),
      ),
    );
  }
}

class _TodayTasksView extends StatelessWidget {
  const _TodayTasksView();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // In Dart, weekday: 1 = Monday, ..., 7 = Sunday
    final todayWeekday = now.weekday;

    return Consumer<TasksProvider>(
      builder: (context, provider, child) {
        final todayTasks = provider.tasks
            .where((t) => t.selectedDays.contains(todayWeekday))
            .toList();

        if (todayTasks.isEmpty) {
          return const Center(
            child: Text(
              'No tasks scheduled for today.',
              style: TextStyle(color: AppConstants.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 80),
          itemCount: todayTasks.length,
          itemBuilder: (context, index) {
            final task = todayTasks[index];
            final status = provider.getTaskStatusForDate(task.id, now);
            final taskTime = DateTime(now.year, now.month, now.day, task.time.hour, task.time.minute);
            final isPast = now.isAfter(taskTime);

            Color bgColor = AppConstants.cardColor;
            if (status == 'done') {
              bgColor = Colors.green.withOpacity(0.15);
            } else if (status == 'not_done') {
              bgColor = Colors.red.withOpacity(0.15);
            }

            return Card(
              color: bgColor,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(
                  task.title,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  task.time.format(context),
                  style: const TextStyle(color: AppConstants.textSecondary),
                ),
                trailing: isPast
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check_circle,
                                color: status == 'done' ? Colors.green : AppConstants.textMuted),
                            onPressed: () => provider.markTaskStatus(task.id, now, 'done'),
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel,
                                color: status == 'not_done' ? Colors.red : AppConstants.textMuted),
                            onPressed: () => provider.markTaskStatus(task.id, now, 'not_done'),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}

class _AllTasksView extends StatelessWidget {
  const _AllTasksView();

  String _formatDays(List<int> days) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (days.length == 7) return 'Everyday';
    final sortedDays = List<int>.from(days)..sort();
    return sortedDays.map((d) => dayNames[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TasksProvider>(
      builder: (context, provider, child) {
        final tasks = provider.tasks;

        if (tasks.isEmpty) {
          return const Center(
            child: Text(
              'No tasks added yet.',
              style: TextStyle(color: AppConstants.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 80),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return Card(
              color: AppConstants.cardColor,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(
                  task.title,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${task.time.format(context)}\n${_formatDays(task.selectedDays)}',
                  style: const TextStyle(color: AppConstants.textSecondary),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppConstants.primaryAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => TaskEditDialog(task: task),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => provider.deleteTask(task.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
