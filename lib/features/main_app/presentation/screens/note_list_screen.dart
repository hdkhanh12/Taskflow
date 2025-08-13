import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_todo_app/features/main_app/data/models/note.dart';
import 'package:my_todo_app/features/main_app/services/note_service.dart';
import '../../../../l10n/app_localizations.dart';
import 'add_edit_note_screen.dart';

enum NoteSortOption {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
}

class NoteListScreen extends StatefulWidget {

  final bool showBackButton;

  const NoteListScreen({super.key, this.showBackButton = false}); // Mặc định là không hiển thị

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final NoteService _noteService = NoteService();

  // Biến trạng thái cho việc sắp xếp
  String _orderBy = 'createdAt';
  bool _descending = true;
  // === BIẾN TRẠNG THÁI MỚI CHO VIỆC CHỌN VÀ XÓA ===
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  // Hàm để trích xuất text từ JSON của Quill
  String _plainTextFromContentJson(String jsonString) {
    try {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      final plainText = jsonData.map((item) => item['insert']).join();
      return plainText.replaceAll('\n', ' ').trim();
    } catch (e) {
      return '';
    }
  }

  // Hàm để bật/tắt lựa chọn một note
  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
      // Tắt chế độ chọn nếu không còn note nào được chọn
      if (_selectedNoteIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  // Hàm để xóa các note đã chọn
  void _deleteSelectedNotes() async {
    if (_selectedNoteIds.isEmpty) return;

    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDelete),
        content: Text('Are you sure you want to delete ${_selectedNoteIds.length} notes?'),        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _noteService.deleteMultipleNotes(_selectedNoteIds);
      setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    // Phần tiêu đề (Notes + count) là chung cho cả 2 layout
    final Widget titleWidget = StreamBuilder<QuerySnapshot>(
      stream: _noteService.getNotesStream(),
      builder: (context, snapshot) {
        final noteCount = snapshot.data?.docs.length ?? 0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(AppLocalizations.of(context)!.notesTab, style: theme.textTheme.displayLarge?.copyWith(fontSize: 32)),
            const SizedBox(width: 10),
            Text(noteCount.toString(), style: theme.textTheme.displayLarge?.copyWith(fontSize: 28, color: Colors.grey)),
          ],
        );
      },
    );

    // Giao diện khi đang ở chế độ chọn (luôn có 1 hàng)
    if (_isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_selectedNoteIds.length} selected', style: theme.textTheme.titleLarge),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedNoteIds.clear();
              }),
            )
          ],
        ),
      );
    }

    // Layout 1: Khi truy cập từ HomeScreen (có nút back)
    if (widget.showBackButton) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(),
                _buildSortButton(context),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: titleWidget,
          ),
        ],
      );
    }

    // Layout 2: Khi truy cập từ MainLayout (không có nút back)
    else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            titleWidget,
            _buildSortButton(context),
          ],
        ),
      );
    }
  }

  // Widget cho việc sắp xếp
  Widget _buildSortButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<NoteSortOption>(
      onSelected: (option) {
        setState(() {
          switch (option) {
            case NoteSortOption.nameAsc:
              _orderBy = 'title';
              _descending = false;
              break;
            case NoteSortOption.nameDesc:
              _orderBy = 'title';
              _descending = true;
              break;
            case NoteSortOption.dateAsc:
              _orderBy = 'createdAt';
              _descending = false;
              break;
            case NoteSortOption.dateDesc:
              _orderBy = 'createdAt';
              _descending = true;
              break;
          }
        });
      },
      icon: Icon(
        Icons.sort,
        // Kiểm tra theme và chọn màu phù hợp
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: NoteSortOption.dateDesc, child: Text(AppLocalizations.of(context)!.sortbyDateNewest)),
        PopupMenuItem(value: NoteSortOption.dateAsc, child: Text(AppLocalizations.of(context)!.sortbyDateOldest)),
        PopupMenuItem(value: NoteSortOption.nameAsc, child: Text(AppLocalizations.of(context)!.sortbyNameAZ)),
        PopupMenuItem(value: NoteSortOption.nameDesc, child: Text(AppLocalizations.of(context)!.sortbyNameZA)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy theme hiện tại
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          _isSelectionMode = false;
          _selectedNoteIds.clear();
        });
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Inter',
            color: theme.textTheme.bodyMedium?.color,
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context), // Truyền context vào
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _noteService.getNotesStream(orderBy: _orderBy, descending: _descending),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text(AppLocalizations.of(context)!.norecentnotes));
                      }

                      final notes = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Note(
                          id: doc.id,
                          title: data['title'] ?? '',
                          contentJson: data['contentJson'] ?? '',
                          colorValue: data['colorValue'] ?? 0,
                          isFavorite: data['isFavorite'] ?? false,
                          createdAt: data['createdAt'] ?? Timestamp.now(),
                        );
                      }).toList();

                      return MasonryGridView.count(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final isSelected = _selectedNoteIds.contains(note.id);

                          return InkWell(
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(note.id!);
                              } else {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note)));
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                _isSelectionMode = true;
                                _toggleSelection(note.id!);
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                // SỬA LẠI MÀU NỀN
                                color: Color(note.colorValue).withOpacity(theme.brightness == Brightness.dark ? 0.4 : 1),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: theme.colorScheme.primary, width: 3) : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (note.title.isNotEmpty)
                                    Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (note.title.isNotEmpty) const SizedBox(height: 8),
                                  Text(
                                    _plainTextFromContentJson(note.contentJson),
                                    maxLines: 7,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(note.isFavorite ? Icons.star : Icons.star_border, size: 20),
                                      Text(
                                        DateFormat('dd/MM').format(note.createdAt.toDate()),
                                        style: TextStyle(
                                          fontSize: 12,
                                          // Kiểm tra theme và chọn màu tương ứng
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white70 // Màu cho theme tối
                                              : Colors.black54, // Màu cho theme sáng
                                        ),
                                      ),
                                    ],
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
        ),
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton(
          onPressed: _deleteSelectedNotes,
          backgroundColor: Colors.redAccent,
          child: Image.asset('assets/images/delete.png', height: 24, width: 24, color: Colors.white),
        )
            : FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditNoteScreen()));
          },
          // Lấy màu từ theme
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 50),
        ),
      ),
    );
  }
}