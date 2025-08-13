import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:my_todo_app/features/main_app/data/models/note.dart';
import 'package:my_todo_app/features/main_app/data/models/task.dart';
import 'package:my_todo_app/features/main_app/presentation/providers/timer_provider.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/add_edit_note_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/add_edit_task_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/note_list_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/settings_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/todays_tasks_screen.dart';
import 'package:my_todo_app/features/main_app/services/note_service.dart';
import 'package:my_todo_app/features/main_app/services/task_service.dart';
import 'package:my_todo_app/features/main_app/services/user_service.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _plainTextFromContentJson(String jsonString) {
    try {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      if (jsonData.isEmpty) return "";
      final plainText = jsonData.map((item) => item['insert']).join();
      return plainText.replaceAll('\n', ' ').trim();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Expanded(flex: 3, child: _buildPomodoroCard(context)),
              const SizedBox(height: 24),
              Expanded(flex: 4, child: _buildTodayTasksSection(context)),
              const SizedBox(height: 24),
              Expanded(flex: 3, child: _buildNotesSection(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hour = DateTime.now().hour;
    String greeting;
    if (hour > 6 && hour < 12) {
      greeting = AppLocalizations.of(context)!.goodMorning;
    } else if (hour < 18) {
      greeting = AppLocalizations.of(context)!.goodAfternoon;
    } else {
      greeting = AppLocalizations.of(context)!.goodEvening;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting ${user?.displayName ?? ''}',
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                AppLocalizations.of(context)!.quote,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        StreamBuilder<DocumentSnapshot>(
            stream: UserService().getUserProfileStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircleAvatar(radius: 24);
              final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

              return IconButton(
                padding: EdgeInsets.zero,
                icon: CircleAvatar(
                  radius: 24,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  backgroundColor: userData['avatarBackgroundColorValue'] != null ? Color(userData['avatarBackgroundColorValue']) : Colors.grey[200],
                  child: user?.photoURL == null && userData['avatarIconPath'] != null
                      ? SvgPicture.asset(userData['avatarIconPath'], height: 24, width: 24)
                      : (user?.photoURL == null ? Text(user?.displayName?.substring(0, 1).toUpperCase() ?? 'U') : null),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              );
            }),
      ],
    );
  }

  Widget _buildPomodoroCard(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timer.titleController.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    timer.sessionCountText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      // Kiểm tra xem có phải là theme tối không
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Nếu là theme tối, dùng màu trắng
                            : Colors.grey[900], // Nếu là theme sáng, dùng màu xám đậm
                        fontWeight: FontWeight.w500
                    ),                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${timer.formattedTime} left',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      // Kiểm tra xem có phải là theme tối không
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Nếu là theme tối, dùng màu trắng
                            : Colors.grey[900], // Nếu là theme sáng, dùng màu xám đậm
                        fontWeight: FontWeight.w500
                    ),                  ),
                  const Spacer(),
                  IconButton(
                    iconSize: 64,
                    padding: EdgeInsets.zero,
                    icon: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFBEC4FE).withOpacity(theme.brightness == Brightness.light ? 1 : 0.2), // nền vòng tròn màu #BEC4FE
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        timer.isTimerRunning ? Icons.pause : Icons.play_arrow,
                        // Sửa lại dòng này
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        size: 48,
                      ),
                    ),
                    onPressed: timer.isTimerRunning ? timer.pauseTimer : timer.resumeTimer,
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayTasksSection(BuildContext context) {
    final theme = Theme.of(context);
    final TaskService taskService = TaskService();
    String _extractTime(String fullTime) {
      if (fullTime.contains(' ')) return fullTime.split(' ').last;
      return fullTime;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: taskService.getTasksForTodayStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final taskCount = docs.length;

        return Column(
          children: [
            _buildSectionHeader(context, AppLocalizations.of(context)!.today, '$taskCount tasks left', AppLocalizations.of(context)!.viewAll, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TodaysTasksScreen()));
            }),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (docs.isEmpty)
              Expanded(child: Center(child: Text(AppLocalizations.of(context)!.notaskstoday, style: const TextStyle(color: Colors.grey))))
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final task = Task(
                      id: docs[index].id,
                      title: data['title'] ?? '',
                      time: data['time'] ?? '',
                      category: data['categoryName'] ?? '',
                      categoryId: data['categoryId'] ?? '',
                      color: Color(data['colorValue'] ?? 0),
                      isCompleted: data['isCompleted'] ?? false,
                    );
                    return InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task))),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          // SỬA LẠI Ở ĐÂY: Dùng màu của task nhưng vẫn giữ độ trong suốt
                          color: task.color.withOpacity(theme.brightness == Brightness.dark ? 0.6 : 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // === PHẦN THAY ĐỔI CHÍNH ===
                                // Bọc CircleAvatar bằng GestureDetector
                                GestureDetector(
                                  // onTap của riêng ô tròn sẽ đánh dấu hoàn thành
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (task.id != null && task.categoryId != null) {
                                      taskService.updateTaskCompletion(task.id!, task.categoryId!, true);
                                    }
                                  },
                                  child: const CircleAvatar(radius: 12, backgroundColor: Colors.white),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              ],
                            ),
                            const Spacer(),
                            Text(task.title, style: Theme.of(context).textTheme.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),

                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  task.category,
                                  // Thay thế TextStyle cố định...
                                  // style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF242424), fontWeight: FontWeight.w400),

                                  // ...bằng cách gọi style từ Theme đã định nghĩa
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                Text(
                                  _extractTime(task.time),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // Trong class HomeScreen

  // Trong class HomeScreen

  Widget _buildNotesSection(BuildContext context) {
    final theme = Theme.of(context);
    final NoteService noteService = NoteService();

    return StreamBuilder<QuerySnapshot>(
      stream: noteService.getLatestNoteStream(), // Chỉ cần stream lấy note mới nhất
      builder: (context, snapshot) {
        // Lấy số lượng note từ một stream khác để không bị lẫn lộn
        final noteCountStream = noteService.getNotesStream();

        return Column(
          children: [
            // Header
            StreamBuilder<QuerySnapshot>(
                stream: noteCountStream,
                builder: (context, countSnapshot) {
                  final noteCount = countSnapshot.data?.docs.length ?? 0;
                  return _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.notes,
                    '$noteCount notes',
                    AppLocalizations.of(context)!.viewAll,
                        () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteListScreen(showBackButton: true)));
                    },
                  );
                }
            ),
            const SizedBox(height: 16),

            // Phần hiển thị thẻ note
            if (snapshot.connectionState == ConnectionState.waiting)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              Expanded(child: Center(child: Text(AppLocalizations.of(context)!.norecentnotes, style: const TextStyle(color: Colors.grey))))
            else
              Expanded(
                child: LayoutBuilder(
                    builder: (context, constraints) {
                      final noteDoc = snapshot.data!.docs.first;
                      final noteData = noteDoc.data() as Map<String, dynamic>;
                      // TẠO BIẾN note Ở ĐÂY
                      final note = Note(
                        id: noteDoc.id,
                        title: noteData['title'] ?? '',
                        contentJson: noteData['contentJson'] ?? '',
                        colorValue: noteData['colorValue'] ?? 0,
                        isFavorite: noteData['isFavorite'] ?? false,
                        createdAt: noteData['createdAt'] ?? Timestamp.now(),
                      );

                      return InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note))),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            // Tăng opacity nếu là theme sáng, giảm nếu là theme tối
                            color: Color(note.colorValue).withOpacity(theme.brightness == Brightness.light ? 1 : 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bây giờ có thể dùng 'note' ở đây
                              Text(
                                note.title,
                                style: Theme.of(context).textTheme.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  _plainTextFromContentJson(note.contentJson),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: (constraints.maxHeight / 24).floor(), // Tự tính số dòng tối đa
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    // Kiểm tra xem có phải là theme tối không
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white // Nếu là theme tối, dùng màu trắng
                                          : Colors.grey[900], // Nếu là theme sáng, dùng màu xám đậm
                                      fontWeight: FontWeight.w500
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(note.isFavorite ? Icons.star : Icons.star_border, size: 20, color: Colors.orangeAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd/MM').format(note.createdAt.toDate()),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      // Kiểm tra xem có phải là theme tối không
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white // Nếu là theme tối, dùng màu trắng
                                            : Colors.grey[900], // Nếu là theme sáng, dùng màu xám đậm
                                        fontWeight: FontWeight.w500
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String countText, String actionText, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Text(countText, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        TextButton(
          onPressed: onTap,
          child: Text(actionText, style: Theme.of(context).textTheme.labelLarge),

        ),
      ],
    );
  }
}