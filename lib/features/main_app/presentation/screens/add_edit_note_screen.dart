import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_todo_app/features/main_app/data/models/note.dart';
import 'package:my_todo_app/features/main_app/services/note_service.dart';

import '../../../../l10n/app_localizations.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;
  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final NoteService _noteService = NoteService();
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();

  final List<Color> _colors = [
    const Color(0xFFC9E4DE), const Color(0xFFD5E6FF), const Color(0xFFFFF2D1),
    const Color(0xFFFDE7E5), const Color(0xFFE5DEFE), const Color(0xFFFFD9D9),
  ];
  int _selectedColorIndex = 0;

  bool get _isEditMode => widget.note != null;

  @override
  void initState() {
    super.initState();
    _loadNoteData();
  }

  void _loadNoteData() {
    if (_isEditMode) {
      _titleController.text = widget.note!.title;
      try {
        final contentJson = jsonDecode(widget.note!.contentJson);
        _controller = QuillController(
          document: Document.fromJson(contentJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _controller = QuillController.basic();
      }
      _selectedColorIndex = _colors.indexWhere((c) => c.value == widget.note!.colorValue);
      if (_selectedColorIndex == -1) _selectedColorIndex = 0;
    } else {
      _controller = QuillController.basic();
    }
  }

  Future<bool> _saveNote() async {
    final title = _titleController.text.trim();
    final contentJson = jsonEncode(_controller.document.toDelta().toJson());

    if (title.isEmpty && _controller.document.isEmpty()) {
      return true;
    }

    final noteData = {
      'title': title.isEmpty ? 'Untitled Note' : title,
      'contentJson': contentJson,
      'colorValue': _colors[_selectedColorIndex].value,
      'isFavorite': widget.note?.isFavorite ?? false,
      'createdAt': _isEditMode ? widget.note!.createdAt : Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    try {
      if (_isEditMode) {
        await _noteService.updateNote(widget.note!.id!, noteData);
      } else {
        await _noteService.addNote(noteData);
      }
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final bool shouldPop = await _saveNote();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: const BackButton(),
          actions: [
            SizedBox(
              height: 32,
              width: MediaQuery.of(context).size.width * 0.7,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: _colors.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_selectedColorIndex == index)
                          CircleAvatar(radius: 16, backgroundColor: isDarkMode ? Colors.white : Colors.black),
                        CircleAvatar(radius: 14, backgroundColor: _colors[index]),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.notesTab,
                  border: InputBorder.none,
                ),
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
            ),
            Container(
              color: _colors[_selectedColorIndex].withOpacity(0.15),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: QuillToolbar.simple(
                  configurations: QuillSimpleToolbarConfigurations(
                    controller: _controller,
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      base: QuillToolbarBaseButtonOptions(
                        iconTheme: QuillIconTheme(
                          iconButtonUnselectedData: IconButtonData(
                            style: IconButton.styleFrom(
                              foregroundColor: theme.iconTheme.color, // non-selected icon color
                            ),
                          ),
                          iconButtonSelectedData: IconButtonData(
                            style: IconButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary, // selected icon color
                            ),
                          ),
                        ),
                      ),
                    ),
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showColorButton: true,
                    showListBullets: true,
                    showListNumbers: true,
                    showUndo: true,
                    showRedo: true,
                    showStrikeThrough: false,
                    showQuote: false,
                    showIndent: false,
                    showLink: false,
                    showClearFormat: false,
                    showHeaderStyle: false,
                    showListCheck: false,
                    showCodeBlock: false,
                    showSearchButton: false,
                    sharedConfigurations: const QuillSharedConfigurations(
                      locale: Locale('en'),
                  ),
                ),
              ),
            ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: QuillEditor.basic(
                  configurations: QuillEditorConfigurations(
                    controller: _controller,
                    padding: EdgeInsets.zero,
                    readOnly: false,
                    customStyles: DefaultStyles(
                      paragraph: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        const VerticalSpacing(1.0, 0),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}