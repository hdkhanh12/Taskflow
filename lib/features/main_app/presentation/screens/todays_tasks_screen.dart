import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_app/features/main_app/data/models/task.dart';
import 'package:my_todo_app/features/main_app/presentation/widgets/task_item_widget.dart';
import 'package:my_todo_app/features/main_app/services/task_service.dart';

import '../../../../l10n/app_localizations.dart';
import 'add_edit_task_screen.dart';

class TodaysTasksScreen extends StatelessWidget {
  const TodaysTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TaskService taskService = TaskService();
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hàng chứa nút Back
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: BackButton(),
            ),

            // StreamBuilder cho cả header và list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: taskService.getTasksForTodayStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildHeader(context, docs.length),
                      ),
                      const SizedBox(height: 20),

                      // Danh sách Task
                      Expanded(
                        child: docs.isEmpty
                            ? Center(child: Text(AppLocalizations.of(context)!.notaskstoday))
                            : _buildTaskList(docs, context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int taskCount) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(AppLocalizations.of(context)!.todayTasks, style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
        const SizedBox(width: 10),
        Text(taskCount.toString(), style: theme.textTheme.displayLarge?.copyWith(fontSize: 26, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTaskList(List<QueryDocumentSnapshot> docs, BuildContext context) {
    final tasks = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Task(
        id: doc.id,
        title: data['title'] ?? '',
        // time: data['time'] ?? '',
        category: data['categoryName'] ?? '',
        categoryId: data['categoryId'] ?? '',
        color: Color(data['colorValue'] ?? 0),
        isCompleted: data['isCompleted'] ?? false,
        dueDate: data['dueDate'] ?? '',
        dueTimestamp: data['dueTimestamp'],
      );
    }).toList();

    final Map<String, List<Task>> groupedTasks = {};
    for (var task in tasks) {
      if (groupedTasks[task.category] == null) {
        groupedTasks[task.category] = [];
      }
      groupedTasks[task.category]!.add(task);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      children: groupedTasks.entries.map((entry) {
        return _buildTaskCategory(context, entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildTaskCategory(BuildContext context, String categoryName, List<Task> tasks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(categoryName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...tasks.map((task) {
            return TaskItemWidget(
              task: task,
              // isSelected: Luôn là false vì màn hình này không có chế độ chọn
              isSelected: false,
              // onTap: Mở màn hình chỉnh sửa như bình thường
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
                );
              },
              // onLongPress: Không làm gì cả
              onLongPress: () {},
            );
          }).toList(),
        ],
      ),
    );
  }
}