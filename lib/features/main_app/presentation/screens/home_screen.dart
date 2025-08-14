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
              Expanded(flex: 2, child: _buildPomodoroCard(context)),
              const SizedBox(height: 24),
              Expanded(flex: 5, child: _buildTodayTasksSection(context)),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[900],
                        fontWeight: FontWeight.w500
                    ),                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${timer.formattedTime} left',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[900],
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
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        size: 40,
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

  Widget _buildTaskCard(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final TaskService taskService = TaskService();

    // Tính toán chiều rộng cho mỗi card
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 48 - 16) / 2; // 48=padding(24*2), 16=spacing

    return SizedBox(
      width: itemWidth,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task))),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: task.color.withOpacity(theme.brightness == Brightness.dark ? 0.6 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Giúp Column co lại theo nội dung
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
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
              // Dùng SizedBox thay cho Spacer/Expanded để có khoảng cách cố định
              const SizedBox(height: 12),
              Text(
                task.title,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded( // Dùng Expanded ở đây để category không bị tràn nếu quá dài
                    child: Text(
                      task.category,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildTaskTimeWidget(task, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTimeWidget(Task task, BuildContext context) {
    if (task.dueTimestamp == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    final dateTime = task.dueTimestamp!.toDate();
    final String displayText = task.isAllDay
        ? DateFormat('dd/MM').format(dateTime)
        : DateFormat('HH:mm').format(dateTime);

    return Text(
      displayText,
      style: TextStyle(
        fontSize: 12,
        color: theme.textTheme.bodySmall?.color,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

  }

  Widget _buildTodayTasksSection(BuildContext context) {
    final TaskService taskService = TaskService();

    return StreamBuilder<QuerySnapshot>(
      stream: taskService.getTasksForTodayStream(),
      builder: (context, snapshot) {
        // Luôn lấy số lượng task để hiển thị trên header
        final taskCount = snapshot.data?.docs.length ?? 0;

        // Cấu trúc chính luôn là một Column
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header luôn được hiển thị, bất kể có task hay không
            _buildSectionHeader(
              context,
              AppLocalizations.of(context)!.today,
              '$taskCount tasks left',
              AppLocalizations.of(context)!.viewAll,
                  () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TodaysTasksScreen()));
              },
            ),
            const SizedBox(height: 16),

            // 2. Nội dung bên dưới được tách ra hàm riêng và luôn nằm trong Expanded
            Expanded(
              child: _buildTodayTasksContent(context, snapshot),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodayTasksContent(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    // --- Xử lý các trạng thái ban đầu ---
    if (snapshot.hasError) {
      return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.notaskstoday, style: const TextStyle(color: Colors.grey)));
    }

    // --- Dùng Wrap để hiển thị ---
    final docs = snapshot.data!.docs;
    return Wrap(
      spacing: 16,    // Khoảng cách ngang
      runSpacing: 16, // Khoảng cách dọc
      alignment: WrapAlignment.start,
      children: docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final task = Task(
          id: doc.id,
          title: data['title'] ?? '',
          category: data['categoryName'] ?? '',
          categoryId: data['categoryId'] ?? '',
          color: Color(data['colorValue'] ?? 0),
          isCompleted: data['isCompleted'] ?? false,
          dueTimestamp: data['dueTimestamp'],
          isAllDay: data['isAllDay'] ?? false,
        );
        return _buildTaskCard(context, task);
      }).toList(),
    );
  }

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
                            color: Color(note.colorValue).withOpacity(theme.brightness == Brightness.light ? 1 : 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.grey[900],
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
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.grey[900],
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