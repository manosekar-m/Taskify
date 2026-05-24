import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/hive_service.dart';
import '../widgets/dashboard_widgets.dart';

class RoughNotesScreen extends StatefulWidget {
  const RoughNotesScreen({super.key});

  @override
  State<RoughNotesScreen> createState() => _RoughNotesScreenState();
}

class _RoughNotesScreenState extends State<RoughNotesScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final list = await HiveService().getNotes();
      setState(() {
        _notes = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openNoteDialog({Note? existing, int? index}) {
    final theme = Theme.of(context);
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
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
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (title.isEmpty && content.isEmpty) return;

                      final note = Note(
                        id: existing?.id,
                        title: title.isNotEmpty ? title : 'Untitled',
                        content: content,
                        createdAt: existing?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      if (isEdit) {
                        await HiveService().updateNote(note);
                      } else {
                        await HiveService().createNote(note);
                      }
                      _fetchNotes();
                      if (!ctx.mounted) return;
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
            onPressed: () async {
              Navigator.pop(ctx);
              await HiveService().deleteNote(_notes[index].id!);
              _fetchNotes();
              if (!mounted) return;
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

  String _formatDate(DateTime dt) {
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
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
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
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        final List<Color> pastelColors = [
                          const Color(0xFFE3F2FD), // Blue
                          const Color(0xFFE8F5E9), // Green
                          const Color(0xFFFFF3E0), // Orange
                          const Color(0xFFF3E5F5), // Purple
                          const Color(0xFFFCE4EC), // Pink
                          const Color(0xFFE0F2F1), // Teal
                        ];
                        final Color noteColor = pastelColors[index % pastelColors.length];
                        final bool isDark = theme.brightness == Brightness.dark;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? theme.cardColor : noteColor,
                              borderRadius: BorderRadius.circular(24),
                              border: isDark ? Border.all(color: theme.dividerColor) : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(alpha: 0.3),
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  note.title,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                    color: isDark ? theme.primaryColor : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              _noteActionBtn(
                                                icon: Icons.edit_rounded,
                                                color: theme.primaryColor,
                                                onTap: () => _openNoteDialog(existing: note, index: index),
                                              ),
                                              const SizedBox(width: 8),
                                              _noteActionBtn(
                                                icon: Icons.delete_rounded,
                                                color: Colors.redAccent,
                                                onTap: () => _deleteNote(index),
                                              ),
                                            ],
                                          ),
                                          if (note.content.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              note.content,
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: isDark ? theme.hintColor : Colors.black54,
                                                height: 1.6,
                                              ),
                                              maxLines: 5,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_filled_rounded,
                                                  size: 14, color: (isDark ? theme.hintColor : Colors.black45).withValues(alpha: 0.5)),
                                              const SizedBox(width: 6),
                                              Text(
                                                _formatDate(note.updatedAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: (isDark ? theme.hintColor : Colors.black45).withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
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
  Widget _noteActionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
