import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_todo_app/features/main_app/data/models/category.dart';
import 'package:my_todo_app/features/main_app/data/models/task.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/add_edit_task_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/all_folders_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/widgets/task_item_widget.dart';
import 'package:my_todo_app/features/main_app/services/category_service.dart';
import 'package:my_todo_app/features/main_app/services/task_service.dart';

import '../../../../l10n/app_localizations.dart';
import 'add_edit_folder_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  final CategoryService _categoryService = CategoryService();
  bool _isSelectionMode = false;
  final Set<String> _selectedTaskIds = {}; // Dùng Set để tránh trùng lặp
  List<Task> _currentTasks = [];

  String? _selectedCategoryId;


  void _handleTaskTap(Task task) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedTaskIds.contains(task.id)) {
          _selectedTaskIds.remove(task.id);
        } else {
          _selectedTaskIds.add(task.id!);
        }
        if (_selectedTaskIds.isEmpty) {
          _isSelectionMode = false;
        }
      });
    } else {
      // HÀNH ĐỘNG KHI NHẤN BÌNH THƯỜNG
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
      );
    }
  }

  void _handleTaskLongPress(Task task) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedTaskIds.add(task.id!);
      });
    }
  }

  void _deleteSelectedTasks() async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDelete),
        content: Text('Are you sure you want to delete ${_selectedTaskIds.length} notes?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      // Lặp qua các ID đã chọn để xóa
      for (String taskId in _selectedTaskIds) {
        // Tìm lại categoryId từ danh sách task hiện tại
        final taskToDelete = _currentTasks.firstWhere((task) => task.id == taskId);
        await _taskService.deleteTask(taskId, taskToDelete.categoryId!);
      }

      // Reset trạng thái sau khi xóa
      setState(() {
        _isSelectionMode = false;
        _selectedTaskIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor: const Color(0xFFF8F8F8),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'Inter',
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
      floatingActionButton: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final isDarkMode = theme.brightness == Brightness.dark;

            const baseColor = Color(0xFFBEC4FE);

            final fabColor = baseColor.withOpacity(isDarkMode ? 1.0 : 1.0);

            return _isSelectionMode
            // NẾU ĐANG Ở CHẾ ĐỘ CHỌN: Hiển thị nút Xóa
                ? FloatingActionButton(
              onPressed: _deleteSelectedTasks,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.delete, color: Colors.white),
            )
            // NẾU KHÔNG: Hiển thị nút SpeedDial như cũ
                : SpeedDial(
              child: const Icon(Icons.add, color: Colors.white, size: 50),
              activeIcon: Icons.close,
              backgroundColor: fabColor,
              foregroundColor: Colors.white,
              buttonSize: const Size(55, 55),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),

              animationDuration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,

              children: [
                SpeedDialChild(
                  child: const Icon(Icons.create_new_folder_outlined),
                  label: AppLocalizations.of(context)!.addFolder,
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AllFoldersScreen()),
                    );
                  },
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                SpeedDialChild(
                  child: const Icon(Icons.note_add_outlined),
                  label: AppLocalizations.of(context)!.addTask,
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.white,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AddEditTaskScreen()),
                    );
                  },
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            );
          },
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
        const SizedBox(width: 48),
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
              );
            }).toList();
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: categories.length + 1, // +1 cho nút "Tất cả"
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _selectedCategoryId == null;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = null),
                  child: _buildAllFoldersCard(isSelected), // Truyền trạng thái isSelected
                );
              }
              // Các nút category
              final category = categories[index - 1];
              final isSelected = _selectedCategoryId == category.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = category.id),
                child: _buildCategoryCard(category, isSelected), // Truyền trạng thái isSelected
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildAllFoldersCard(bool isSelected) {
    final theme = Theme.of(context);
    return Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(
              theme.brightness == Brightness.dark ? 0.6 : 1.0
          ),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: theme.colorScheme.primary, width: 2) : null,

        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.folder_copy_outlined, size: 32),
            const Icon(Icons.inventory_2_outlined, size: 32),
            const Spacer(),
            // Text('All folders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(
              AppLocalizations.of(context)!.allFolders,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),          ],
        ),

    );
  }

  Widget _buildCategoryCard(Category category, bool isSelected) {
    final theme = Theme.of(context);
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: category.color.withOpacity(theme.brightness == Brightness.light ? 1.0 : 0.6),
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 2) : null,
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
          // === THAY THẾ BẰNG STREAMBUILDER ĐỂ ĐẾM THỜI GIAN THỰC ===
          StreamBuilder<int>(
            // Gọi đến hàm đếm mới trong TaskService
            stream: TaskService().getIncompleteTasksCountStreamForCategory(category.id!),
            builder: (context, snapshot) {
              // Lấy số lượng từ stream, nếu chưa có dữ liệu thì hiển thị 0
              final count = snapshot.data ?? 0;

              return Text(
                '$count', // Hiển thị số lượng task
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      //stream: _taskService.getTasksStream(),
      stream: _taskService.getTasksStream(categoryId: _selectedCategoryId),

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Stack trace: ${snapshot.stackTrace}");
          return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final tasks = snapshot.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          final task = Task(
            id: doc.id,
            title: data['title'] ?? 'No Title',
            // time: data['time'] ?? 'Anytime',
            category: data['categoryName'] ?? 'General',
            categoryId: data['categoryId'] ?? '',
            color: Color(data['colorValue'] ?? 0xFFE6F8D1),
            isCompleted: data['isCompleted'] ?? false,
            // dueDate: data['dueDate'] ?? '',
            dueTimestamp: data['dueTimestamp'],
            isAllDay: data['isAllDay'] ?? false,
          );

          return task;
        }).toList();

        // Gán danh sách mới cho biến trạng thái
        _currentTasks = tasks;

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
          ...tasks.map((task) {
            return TaskItemWidget(
              task: task,
              isSelected: _selectedTaskIds.contains(task.id), // Kiểm tra xem có được chọn không
              onTap: () => _handleTaskTap(task),
              onLongPress: () => _handleTaskLongPress(task),
            );
          }).toList(),
        ],
      ),
    );
  }
}