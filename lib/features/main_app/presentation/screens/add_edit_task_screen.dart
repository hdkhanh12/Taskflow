import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart'; // Import gói intl
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/category.dart';
import '../../data/models/task.dart';
import '../../services/category_service.dart';
import '../../services/task_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  // Thêm thuộc tính để nhận Task có sẵn (cho chế độ Edit)
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _titleController = TextEditingController();
  final TaskService _taskService = TaskService();
  final CategoryService _categoryService = CategoryService();

  List<Category> _categories = [];
  Category? _selectedCategory;
  DateTime _selectedTime = DateTime.now();
  bool _isAllDay = false;
  bool get _isEditMode => widget.task != null;
  String? _initialCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  void _fetchInitialData() async {
    // Luôn lấy danh sách categories
    final categoriesSnapshot = await _categoryService.getCategoriesStream().first;
    _categories = categoriesSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Category(
        id: doc.id,
        name: data['name'] ?? '',
        iconPath: data['iconPath'] ?? '',
        color: Color(data['colorValue'] ?? 0xFFFFFFFF),
        taskCount: data['taskCount'] ?? 0,
      );
    }).toList();

    // Nếu là chế độ Edit, điền thông tin có sẵn
    if (_isEditMode) {
      final task = widget.task!;
      _titleController.text = task.title;
      // Lưu lại categoryId ban đầu
      _initialCategoryId = task.categoryId;
      _selectedTime = task.dueTimestamp?.toDate() ?? DateTime.now();
      _selectedCategory = _categories.firstWhere((cat) => cat.id == task.categoryId, orElse: () => _categories.first);
    }
    setState(() {}); // Cập nhật lại giao diện sau khi có dữ liệu
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        // Cập nhật ngày đã chọn, giữ nguyên giờ và phút
        _selectedTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  void _saveTask() async {
    if (_titleController.text.trim().isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saveTaskNote)),
      );
      return;
    }

    String formattedTime;
    if (_isAllDay) {
      formattedTime = 'All day';
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDay = DateTime(_selectedTime.year, _selectedTime.month, _selectedTime.day);

      if (selectedDay == today) {
        formattedTime = 'Today ${DateFormat('HH:mm').format(_selectedTime)}';
      } else if (selectedDay == today.add(const Duration(days: 1))) {
        formattedTime = 'Tomorrow ${DateFormat('HH:mm').format(_selectedTime)}';
      } else {
        formattedTime = DateFormat('EEEE, d/M HH:mm').format(_selectedTime);
      }
    }

    final dueDateString = DateFormat('yyyy-MM-dd').format(_selectedTime);


    final taskData = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      time: formattedTime,
      category: _selectedCategory!.name,
      categoryId: _selectedCategory!.id,
      color: _selectedCategory!.color,
      isCompleted: widget.task?.isCompleted ?? false,
      dueTimestamp: Timestamp.fromDate(_selectedTime),
      dueDate: dueDateString,
    );

    try {
      if (_isEditMode) {
        await _taskService.updateTask(taskData, _initialCategoryId!);
      } else {
        await _taskService.addTask(taskData, _selectedCategory!.id!);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print(e);
    }
  }

  void _showFolderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _categoryService.getCategoriesStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final categories = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Category(
                id: doc.id,
                name: data['name'] ?? '',
                iconPath: data['iconPath'] ?? '',
                color: Color(data['colorValue'] ?? 0xFFFFFFFF),
                taskCount: data['taskCount'] ?? 0,
              );
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: SvgPicture.asset(category.iconPath, height: 24, width: 24),
                  title: Text(category.name),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleMarkAsDone() async {
    if (!_isEditMode || widget.task?.id == null || widget.task?.categoryId == null) return;
    try {
      await _taskService.updateTaskCompletion(
        widget.task!.id!,
        widget.task!.categoryId!,
        !widget.task!.isCompleted,
      );
      if(mounted) Navigator.of(context).pop();
    } catch (e) {
    }
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!')),
    );
  }

  void _handleDelete() async {

    if (!_isEditMode || widget.task?.id == null || widget.task?.categoryId == null) {
       return;
    }

    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDelete),
        content: Text(AppLocalizations.of(context)!.confirmDeleteText),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await _taskService.deleteTask(widget.task!.id!, widget.task!.categoryId!);

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete task: $e")),
          );
        }
      }
    }
  }



  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vùng 1: Điền tên
            Flexible(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(isDarkMode ? 0.3 : 1.0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.taskName,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vùng 2: Chọn giờ
            Text(AppLocalizations.of(context)!.time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Flexible(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(isDarkMode ? 0.3 : 1.0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context)!.allDay, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        Switch(
                          value: _isAllDay,
                          onChanged: (value) => setState(() => _isAllDay = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        InkWell(
                          onTap: _selectDate,
                          child: Text(
                            DateFormat('EEEE, d/M').format(_selectedTime),
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18), // Tăng cỡ chữ
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('HH:mm').format(_selectedTime),
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              itemExtent: 60.0,
                              scrollController: FixedExtentScrollController(initialItem: _selectedTime.hour),
                              onSelectedItemChanged: (int index) {
                                setState(() {
                                  _selectedTime = DateTime(_selectedTime.year, _selectedTime.month, _selectedTime.day, index, _selectedTime.minute);
                                });
                              },
                              children: List.generate(24, (i) {
                                return Center(child: Text('$i', style: const TextStyle(fontSize: 28))); // Tăng cỡ chữ
                              }),
                            ),
                          ),
                          Text(':', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)),
                          Expanded(
                            child: CupertinoPicker(
                              itemExtent: 60.0,
                              scrollController: FixedExtentScrollController(initialItem: _selectedTime.minute),
                              onSelectedItemChanged: (int index) {
                                setState(() {
                                  _selectedTime = DateTime(_selectedTime.year, _selectedTime.month, _selectedTime.day, _selectedTime.hour, index);
                                });
                              },
                              children: List.generate(60, (i) {
                                return Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 28))); // Tăng cỡ chữ
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vùng 3: Chọn thư mục
          Flexible(
            flex: 1,
            child:
            GestureDetector(
              onTap: _showFolderPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(isDarkMode ? 0.3 : 1.0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _selectedCategory != null
                        ? SvgPicture.asset(_selectedCategory!.iconPath, height: 24, width: 24)
                        : const Icon(Icons.folder_open_outlined),
                    const SizedBox(width: 12),
                    Text(
                      _selectedCategory?.name ?? AppLocalizations.of(context)!.selectFolder,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),
        child: _isEditMode
        // Giao diện khi ở chế độ "Edit"
            ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomActionButton(
              context: context,
              iconWidget: Image(
                  image: AssetImage(
                      isDarkMode
                          ? 'assets/images/mark_as_done_dark.png'
                          : 'assets/images/mark_as_done.png'
                  ), height: 30, width: 30),
              label: AppLocalizations.of(context)!.done,
              onTap: _handleMarkAsDone,
            ),
            _buildBottomActionButton(
              context: context,
              iconWidget: Image(
                  image: AssetImage(
                      isDarkMode
                          ? 'assets/images/share_dark.png'
                          : 'assets/images/share.png'
                  ), height: 30, width: 30),

              label: AppLocalizations.of(context)!.share,
              onTap: _handleShare,
            ),
            _buildBottomActionButton(
              context: context,
              iconWidget: Image(
                  image: AssetImage(
                      isDarkMode
                          ? 'assets/images/delete_dark.png'
                          : 'assets/images/delete.png'
                  ), height: 30, width: 30),
              label: AppLocalizations.of(context)!.delete,
              onTap: _handleDelete,
            ),
          ],
        )
        // Giao diện khi ở chế độ "Add"
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            _buildBottomActionButton(
              context: context,
              iconWidget: Image(
                  image: AssetImage(
                      isDarkMode
                          ? 'assets/images/mark_as_done_dark.png'
                          : 'assets/images/mark_as_done.png'
                  ), height: 30, width: 30),
              label: AppLocalizations.of(context)!.create,
              onTap: _saveTask,
            ),
            _buildBottomActionButton(
              context: context,
              iconWidget: Image(
                // Dùng toán tử ba ngôi để chọn đúng file ảnh
                  image: AssetImage(
                      isDarkMode
                          ? 'assets/images/delete_dark.png'
                          : 'assets/images/delete.png'
                  ), height: 30, width: 30),
              label: AppLocalizations.of(context)!.cancel,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButton({
    required BuildContext context,
    required Widget iconWidget,
    required String label,
    required VoidCallback? onTap, // Cho phép onTap là null để vô hiệu hóa nút
    Color? color, // Cho phép truyền màu tùy chỉnh
  }) {
    // Lấy màu chữ mặc định từ theme
    final textColor = color ?? Theme.of(context).textTheme.bodyMedium?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon sẽ tự động thừa hưởng màu từ IconTheme của theme
            iconWidget,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: onTap == null ? Colors.grey : textColor, // Làm mờ chữ nếu nút bị vô hiệu hóa
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}