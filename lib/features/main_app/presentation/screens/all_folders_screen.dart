import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_todo_app/features/main_app/data/models/category.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/add_edit_folder_screen.dart';
import 'package:my_todo_app/features/main_app/services/category_service.dart';

import '../../../../l10n/app_localizations.dart';
import '../../services/task_service.dart';

class AllFoldersScreen extends StatelessWidget {
  const AllFoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CategoryService categoryService = CategoryService();
    final theme = Theme.of(context); // Lấy theme hiện tại

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hàng chứa nút Back và nút Add
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(), // Tự động lấy màu từ theme
                  IconButton(
                    icon: const Icon(Icons.add, size: 28), // Tự động lấy màu
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddEditFolderScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tiêu đề "All folders"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                AppLocalizations.of(context)!.allFolders,
                // Sử dụng style từ theme
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
            ),
            const SizedBox(height: 20),

            // Danh sách các thư mục
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: categoryService.getCategoriesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text(AppLocalizations.of(context)!.nofoldersaddedyet));
                  }

                  final categories = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Category(
                      id: doc.id,
                      name: data['name'] ?? '',
                      iconPath: data['iconPath'] ?? '',
                      color: Color(data['colorValue'] ?? 0xFFFFFFFF),
                      // taskCount: data['taskCount'] ?? 0,
                    );
                  }).toList();

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditFolderScreen(category: category),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            // Thay đổi màu nền theo theme
                            color: category.color.withOpacity(theme.brightness == Brightness.dark ? 0.4 : 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                category.iconPath,
                                height: 28,
                                width: 28,
                              ),
                              const SizedBox(width: 16),
                              Text(category.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              StreamBuilder<int>(
                                // Gọi đến hàm đếm mới trong TaskService
                                stream: TaskService().getIncompleteTasksCountStreamForCategory(category.id!),
                                builder: (context, snapshot) {
                                  // Lấy số lượng từ stream, nếu chưa có dữ liệu thì hiển thị 0
                                  final count = snapshot.data ?? 0;

                                  return Text(
                                    count.toString(), // Hiển thị số lượng task
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}