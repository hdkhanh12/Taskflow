import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_todo_app/core/constants/app_icons.dart';
import 'package:my_todo_app/features/main_app/data/models/category.dart';
import 'package:my_todo_app/features/main_app/services/category_service.dart';

import '../../../../l10n/app_localizations.dart';

class AddEditFolderScreen extends StatefulWidget {
  final Category? category;
  const AddEditFolderScreen({super.key, this.category});

  @override
  State<AddEditFolderScreen> createState() => _AddEditFolderScreenState();
}

class _AddEditFolderScreenState extends State<AddEditFolderScreen> {
  final _categoryService = CategoryService();
  final _nameController = TextEditingController();

  final List<Color> _colors = [
    const Color(0xFFC9E4DE), const Color(0xFFC6E2E9), const Color(0xFFFFF2D1),
    const Color(0xFFFDE7E5), const Color(0xFFE5DEFE), const Color(0xFFFFD9D9),
    const Color(0xFFE6F8D1), const Color(0xFFD5E6FF), const Color(0xFFFFEADD)
  ];

  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  bool get _isEditMode => widget.category != null; // Kiểm tra xem có phải đang ở chế độ Edit không

  @override
  void initState() {
    super.initState();
    // Nếu là chế độ Edit, điền sẵn thông tin của category vào
    if (_isEditMode) {
      final category = widget.category!;
      _nameController.text = category.name;
      _selectedIconIndex = AppIcons.folderIcons.indexOf(category.iconPath);
      _selectedColorIndex = _colors.indexWhere((color) => color.value == category.color.value);

      // Xử lý trường hợp không tìm thấy icon hoặc màu
      if (_selectedIconIndex == -1) _selectedIconIndex = 0;
      if (_selectedColorIndex == -1) _selectedColorIndex = 0;
    }
  }

  void _saveFolder() async {
    if (_nameController.text.trim().isEmpty) return;

    final updatedCategory = Category(
      id: widget.category?.id, // Giữ lại id cũ nếu là edit
      name: _nameController.text.trim(),
      iconPath: AppIcons.folderIcons[_selectedIconIndex],
      color: _colors[_selectedColorIndex],
      // taskCount: widget.category?.taskCount ?? 0,
    );

    try {
      if (_isEditMode) {
        // Gọi hàm update
        await _categoryService.updateCategory(widget.category!.id!, updatedCategory);
      } else {
        // Gọi hàm add
        await _categoryService.addCategory(updatedCategory);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print(e);
    }
  }

  void _deleteFolder() async {
    if (!_isEditMode) return; // Chỉ hoạt động ở chế độ edit

    // Hiển thị hộp thoại xác nhận trước khi xóa
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDelete),
        content: Text(AppLocalizations.of(context)!.confirmDeleteText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Nếu người dùng xác nhận xóa
    if (confirmDelete == true) {
      try {
        await _categoryService.deleteCategory(widget.category!.id!, widget.category!.name);
        if (mounted) {
          // Pop 2 lần để quay về màn hình All Folders
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Xử lý lỗi
        print(e);
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
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        ),
      ),
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 35, left: 20, right: 20),
                padding: const EdgeInsets.fromLTRB(24, 45, 24, 24),
                decoration: BoxDecoration(
                  // Lấy màu từ theme
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.name,
                      style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,),
                    ),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.enterProjectName,
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -10,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _colors[_selectedColorIndex].withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    AppIcons.folderIcons[_selectedIconIndex],
                    height: 48,
                    width: 48,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _colors.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: _colors[index],
                    child: _selectedColorIndex == index
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: AppIcons.folderIcons.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconIndex = index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedIconIndex == index ? _colors[_selectedColorIndex].withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SvgPicture.asset(
                        AppIcons.folderIcons[index],
                        colorFilter: ColorFilter.mode(
                          // Icon trong lưới sẽ đổi màu theo theme
                          isDarkMode ? Colors.white70 : Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Nút Save
                TextButton(
                  onPressed: _saveFolder,
                  child: Text(
                    _isEditMode ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.create,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6C77BF)),
                  ),
                ),
                const SizedBox(width: 8),

                // Nút Delete - Chỉ hiển thị ở chế độ Edit
                if (_isEditMode)
                  TextButton(
                    onPressed: _deleteFolder,
                    child: Text(
                      AppLocalizations.of(context)!.delete,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
                    ),
                  ),
                const SizedBox(width: 8),

                // Nút Exit
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.exit, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600 , color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70 // Màu cho theme tối
                      : Colors.black54)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}