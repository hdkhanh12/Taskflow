import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_todo_app/features/main_app/data/models/category.dart';
import 'package:my_todo_app/features/main_app/data/models/task.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/add_edit_task_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/all_folders_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/widgets/task_item_widget.dart'; // Import file widget mới
import 'package:my_todo_app/features/main_app/services/category_service.dart';
import 'package:my_todo_app/features/main_app/services/task_service.dart';

import '../../../../l10n/app_localizations.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  final CategoryService _categoryService = CategoryService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor: const Color(0xFFF8F8F8),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'Inter',
          // Lấy màu chữ mặc định từ theme
          color: theme.textTheme.bodyMedium?.color ?? Colors.black,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildHeader(context),
              ),
              const SizedBox(height: 20),
              // Vùng Folders
              _buildFolderSection(context),
              const SizedBox(height: 20),
              // Vùng danh sách Tasks
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildTaskList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
          );
        },
        // backgroundColor: const Color(0xFFBEC4FE),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 50,),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StreamBuilder<QuerySnapshot>(
            stream: _taskService.getTasksStream(),
            builder: (context, snapshot) {
              final taskCount = snapshot.data?.docs.length ?? 0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // const Text('Tasks', style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
                  Text(AppLocalizations.of(context)!.tasksTab, style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(taskCount.toString(), style: theme.textTheme.displayLarge?.copyWith(fontSize: 26, color: Colors.grey)),
                  //Text(taskCount.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              );
            }),
        const SizedBox(width: 48), // Placeholder để cân bằng layout
      ],
    );
  }

  Widget _buildFolderSection(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 120,
      child: StreamBuilder<QuerySnapshot>(
        stream: _categoryService.getCategoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          List<Category> categories = [];
          if (snapshot.hasData) {
            categories = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Category(
                id: doc.id,
                name: data['name'] ?? '',
                iconPath: data['iconPath'] ?? '',
                color: Color(data['colorValue'] ?? 0xFFFFFFFF),
                taskCount: data['taskCount'] ?? 0,
              );
            }).toList();
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: categories.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAllFoldersCard();
              }
              final category = categories[index - 1];
              return _buildCategoryCard(category);
            },
          );
        },
      ),
    );
  }

  Widget _buildAllFoldersCard() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllFoldersScreen())),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // color: const Color(0xFFE5DEFE),
          color: theme.colorScheme.primaryContainer.withOpacity(
              theme.brightness == Brightness.dark ? 0.6 : 1.0
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_copy_outlined, size: 32),
            const Spacer(),
            // Text('All folders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(
              AppLocalizations.of(context)!.allFolders,
              // Sử dụng style từ theme
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final theme = Theme.of(context);
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: category.color.withOpacity(theme.brightness == Brightness.light ? 1.0 : 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(category.iconPath, height: 32, width: 32),
          const Spacer(),
          Text(
            category.name,
            // style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${category.taskCount}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _taskService.getTasksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final tasks = snapshot.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return Task(
            id: doc.id,
            title: data['title'] ?? 'No Title',
            time: data['time'] ?? 'Anytime',
            category: data['categoryName'] ?? 'General',
            categoryId: data['categoryId'] ?? '',
            color: Color(data['colorValue'] ?? 0xFFE6F8D1),
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
          children: groupedTasks.entries.map((entry) {
            return _buildTaskCategory(context, entry.key, entry.value);
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.notasks,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.addtasksnote,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCategory(BuildContext context, String categoryName, List<Task> tasks) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(categoryName, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          ...tasks.map((task) => TaskItemWidget(task: task)).toList(),
        ],
      ),
    );
  }
}