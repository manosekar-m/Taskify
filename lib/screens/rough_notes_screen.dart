import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/dashboard_widgets.dart';

class RoughNotesScreen extends StatefulWidget {
  const RoughNotesScreen({super.key});

  @override
  State<RoughNotesScreen> createState() => _RoughNotesScreenState();
}

class _RoughNotesScreenState extends State<RoughNotesScreen> {
  late Box _box;
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _box = Hive.box('settings');
    _loadNotes();
  }

  void _loadNotes() {
    final raw = _box.get('roughNotesList');
    if (raw != null && raw is List) {
      setState(() {
        _notes = List<Map<String, dynamic>>.from(
          raw.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      });
    }
  }

  void _saveNotes() {
    _box.put('roughNotesList', _notes.map((n) => Map<String, dynamic>.from(n)).toList());
  }

  void _openNoteDialog({Map<String, dynamic>? existing, int? index}) {
    final theme = Theme.of(context);
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final contentCtrl = TextEditingController(text: existing?['content'] ?? '');
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isEdit ? 'Edit Note' : 'Add Note',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                _sheetField(theme, titleCtrl, 'Title', maxLines: 1),
                const SizedBox(height: 14),
                _sheetField(theme, contentCtrl, 'Write your note...', maxLines: 6),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (title.isEmpty && content.isEmpty) return;

                      setState(() {
                        final note = {
                          'title': title.isNotEmpty ? title : 'Untitled',
                          'content': content,
                          'createdAt': existing?['createdAt'] ??
                              DateTime.now().millisecondsSinceEpoch,
                          'updatedAt': DateTime.now().millisecondsSinceEpoch,
                        };
                        if (isEdit && index != null) {
                          _notes[index] = note;
                        } else {
                          _notes.insert(0, note);
                        }
                        _saveNotes();
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      isEdit ? 'Save Changes' : 'Add Note',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetField(ThemeData theme, TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(color: theme.primaryColor, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: theme.hintColor),
        ),
      ),
    );
  }

  void _deleteNote(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Delete Note?',
            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
        content: Text(
          'This note will be permanently deleted.',
          style: TextStyle(color: theme.hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notes.removeAt(index);
                _saveNotes();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Note deleted',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.black,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('DELETE',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} • $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Rough Notes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 50),
                ],
              ),
            ),

            // Notes list
            Expanded(
              child: _notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notes_rounded, size: 64, color: theme.dividerColor),
                          const SizedBox(height: 14),
                          Text(
                            'No notes yet',
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to add your first note',
                            style: TextStyle(color: theme.hintColor.withValues(alpha: 0.6), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(25, 10, 25, 100),
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note['title'] ?? 'Untitled',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Edit button
                                      GestureDetector(
                                        onTap: () => _openNoteDialog(
                                            existing: note, index: index),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.edit_rounded,
                                              size: 16, color: Theme.of(context).primaryColor),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Delete button
                                      GestureDetector(
                                        onTap: () => _deleteNote(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.delete_rounded,
                                              size: 16, color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((note['content'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      note['content'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.hintColor,
                                        height: 1.5,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 12, color: theme.hintColor.withValues(alpha: 0.5)),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(note['updatedAt'] ?? note['createdAt'] ?? 0),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.hintColor.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // FAB to add note
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteDialog(),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Note', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }
}
