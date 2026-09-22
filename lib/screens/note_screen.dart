```dart
import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';

import '../services/storage_service.dart';
import '../models/note.dart';
import '../services/translation_service.dart';
import '../main.dart';
import 'main_shell.dart';

class NoteScreen extends StatefulWidget {
  final String activeFY;
  const NoteScreen({super.key, required this.activeFY});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    MainShell.sortNotifier.addListener(_sortData);
  }

  @override
  void dispose() {
    MainShell.sortNotifier.removeListener(_sortData);
    super.dispose();
  }

  void _sortData() {
    final sortType = MainShell.sortNotifier.value;

    setState(() {
      if (sortType == 'a_z') {
        _notes.sort(
          (a, b) => a.title.toLowerCase().compareTo(
                b.title.toLowerCase(),
              ),
        );
      } else if (sortType == 'z_a') {
        _notes.sort(
          (a, b) => b.title.toLowerCase().compareTo(
                a.title.toLowerCase(),
              ),
        );
      } else if (sortType == 'date_wise') {
        _notes.sort((a, b) => b.date.compareTo(a.date));
      }
    });
  }

  Future<void> _loadNotes() async {
    final notes = await StorageService.getNotes(widget.activeFY);

    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _addNote() async {
    final lang = languageNotifier.value;

    if (widget.activeFY.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.translate('select_fy', lang),
          ),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final contentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          TranslationService.translate('add_note', lang),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: TranslationService.translate(
                  'title',
                  lang,
                ),
              ),
            ),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: TranslationService.translate(
                  'content',
                  lang,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              TranslationService.translate('cancel', lang),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final newNote = Note(
                  id: DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  title: titleController.text,
                  content: contentController.text,
                  date: DateTime.now().toString().split(' ')[0],
                  financialYear: widget.activeFY,
                );

                setState(() => _notes.insert(0, newNote));

                await StorageService.saveNotes(
                  widget.activeFY,
                  _notes,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(
              TranslationService.translate('save', lang),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(Note note, int index) async {
    final titleController = TextEditingController(
      text: note.title,
    );
    final contentController = TextEditingController(
      text: note.content,
    );
    final lang = languageNotifier.value;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          TranslationService.translate('edit_note', lang),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: TranslationService.translate(
                  'title',
                  lang,
                ),
              ),
            ),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: TranslationService.translate(
                  'content',
                  lang,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              TranslationService.translate('cancel', lang),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final updatedNote = Note(
                  id: note.id,
                  title: titleController.text,
                  content: contentController.text,
                  date: note.date,
                  financialYear: note.financialYear,
                );

                setState(() {
                  _notes[index] = updatedNote;
                });

                await StorageService.saveNotes(
                  widget.activeFY,
                  _notes,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(
              TranslationService.translate('save', lang),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(int index) async {
    final lang = languageNotifier.value;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          TranslationService.translate('delete_note', lang),
        ),
        content: Text(
          TranslationService.translate(
            'delete_confirm_note',
            lang,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              TranslationService.translate('cancel', lang),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              TranslationService.translate('delete', lang),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _notes.removeAt(index));

      await StorageService.saveNotes(
        widget.activeFY,
        _notes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(
                          note.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(note.content),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<String>(
                              valueListenable: dateTypeNotifier,
                              builder:
                                  (context, dateType, _) {
                                String displayDate = note.date;

                                try {
                                  if (dateType == 'BS') {
                                    displayDate = DateTime.parse(
                                      note.date,
                                    )
                                        .toNepaliDateTime()
                                        .format('yyyy-MM-dd');
                                  }
                                } catch (e) {
                                  // Fallback to original date.
                                }

                                return Text(
                                  displayDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        trailing:
                            PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') {
                              _editNote(note, index);
                            } else if (val == 'delete') {
                              _deleteNote(index);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                TranslationService.translate(
                                  'edit',
                                  lang,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                TranslationService.translate(
                                  'delete',
                                  lang,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addNote,
            child: const Icon(Icons.note_add),
          ),
        );
      },
    );
  }
}
```
