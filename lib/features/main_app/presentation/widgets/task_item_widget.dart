import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_todo_app/features/main_app/data/models/task.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/add_edit_task_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/task_service.dart';

class TaskItemWidget extends StatefulWidget {
  final Task task;

  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onLongPress,
    required this.onTap,
  });

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

    final scaleEffect = widget.isSelected ? 0.95 : 1.0;

    return InkWell(
      /*
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: widget.task)),
        );
      },*/

      onTap: widget.onTap,
      onLongPress: widget.onLongPress,

      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(

        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut, // Thêm đường cong để hiệu ứng mượt hơn

        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: widget.task.color.withOpacity(isDarkMode ? 0.6 : 1.0),
          borderRadius: BorderRadius.circular(10),
          border: widget.isSelected
              ? Border.all(color: Color(0xFF6C77BF), width: 3)
              : null,
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

                  if (widget.task.dueTimestamp != null) // Chỉ hiển thị nếu có ngày giờ
                    Text(
                      widget.task.isAllDay
                      // Nếu là cả ngày -> Định dạng: Ngày/Tháng
                          ? DateFormat('dd/MM').format(widget.task.dueTimestamp!.toDate())
                      // Nếu không -> Định dạng: Ngày/Tháng Giờ:Phút
                          : DateFormat('dd/MM HH:mm').format(widget.task.dueTimestamp!.toDate()),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isCompleted ? completedColor : secondaryTextColor,
                      ),
                    ),
                  /*
                  // --- PHẦN HIỆU ỨNG CHỌN (MỚI) ---
                  // Lớp phủ màu xanh mờ
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        // Chỉ hiện lớp phủ khi được chọn
                        color: widget.isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                      ),
                    ),
                  ),

                  // Icon dấu tick (✓)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.blue, size: 16),
                    )
                    // Áp dụng hiệu ứng từ flutter_animate
                        .animate(target: widget.isSelected ? 1 : 0) // Play/Reverse dựa trên isSelected
                        .fade(duration: 200.ms) // Hiệu ứng mờ/hiện
                        .scale(duration: 200.ms, curve: Curves.easeOutBack), // Hiệu ứng phóng to/thu nhỏ
                  ),*/
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}