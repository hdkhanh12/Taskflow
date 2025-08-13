import 'package:flutter/material.dart';
import 'package:my_todo_app/features/main_app/data/models/task.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/add_edit_task_screen.dart';

import '../../services/task_service.dart';

class TaskItemWidget extends StatefulWidget {
  final Task task;
  const TaskItemWidget({super.key, required this.task});

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget> {
  late bool _isCompleted;
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.isCompleted;
  }

  void _toggleCompletion() {
    setState(() {
      _isCompleted = !_isCompleted;
    });
    if (widget.task.id != null && widget.task.categoryId != null) {
      _taskService.updateTaskCompletion(widget.task.id!, widget.task.categoryId!, _isCompleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Xác định màu chữ phụ thuộc vào theme
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final completedColor = isDarkMode ? Colors.white54 : Colors.grey;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: widget.task)),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: widget.task.color.withOpacity(isDarkMode ? 0.6 : 1.0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleCompletion,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  // color: isDarkMode ? theme.scaffoldBackgroundColor : Colors.white,
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _isCompleted ? completedColor : widget.task.color, width: 2),
                ),
                child: _isCompleted ? Icon(Icons.check, size: 16, color: completedColor) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isCompleted ? completedColor : primaryTextColor,
                        ),
                      ),
                      if (_isCompleted)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(height: 1, color: completedColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Phần hiển thị tên category
                  Text(
                    widget.task.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isCompleted ? completedColor : secondaryTextColor,
                    ),
                  ),
                  Text(
                    widget.task.time,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isCompleted ? completedColor : secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}