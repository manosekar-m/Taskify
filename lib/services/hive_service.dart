import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/note.dart';
import '../models/user.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String taskBoxName = 'tasks';
  static const String subtaskBoxName = 'subtasks';
  static const String noteBoxName = 'notes';
  static const String userBoxName = 'users';

  Box<Task> get _taskBox => Hive.box<Task>(taskBoxName);
  Box<Subtask> get _subtaskBox => Hive.box<Subtask>(subtaskBoxName);
  Box<Note> get _noteBox => Hive.box<Note>(noteBoxName);
  Box<User> get _userBox => Hive.box<User>(userBoxName);
  Box get _sessionBox => Hive.box('session');

  final _uuid = const Uuid();

  // Auth Operations
  String? get currentUserId => _sessionBox.get('userId');

  Future<User?> get currentUser async {
    final id = currentUserId;
    if (id == null) return null;
    return _userBox.get(id);
  }

  Future<User> registerUser(String name, String email, String password) async {
    final id = _uuid.v4();
    final user = User(id: id, name: name, email: email, password: password);
    await _userBox.put(id, user);
    await _sessionBox.put('userId', id);
    await _migrateOrphanData(id);
    return user;
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      final user = _userBox.values.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && u.password == password
      );
      await _sessionBox.put('userId', user.id);
      await _migrateOrphanData(user.id);
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> _migrateOrphanData(String userId) async {
    // Migrate Tasks
    final orphanTasks = _taskBox.values.where((t) => t.userId == null).toList();
    for (var t in orphanTasks) {
      t.userId = userId;
      await t.save();
    }
    // Migrate Notes
    final orphanNotes = _noteBox.values.where((n) => n.userId == null).toList();
    for (var n in orphanNotes) {
      n.userId = userId;
      await n.save();
    }
  }

  Future<void> logout() async {
    await _sessionBox.delete('userId');
  }

  // Task Operations
  Future<List<Task>> getTasks(DateTime date) async {
    final userId = currentUserId;
    return _taskBox.values.where((task) {
      return task.userId == userId &&
             task.startDateTime.year == date.year &&
             task.startDateTime.month == date.month &&
             task.startDateTime.day == date.day;
    }).toList()..sort((a, b) => a.position.compareTo(b.position));
  }

  Future<Task> createTask(Task task) async {
    task.id ??= _uuid.v4();
    task.userId = currentUserId;
    await _taskBox.put(task.id, task);
    return task;
  }

  Future<void> updateTask(Task task) async {
    await task.save();
  }

  Future<void> deleteTask(String taskId) async {
    await _taskBox.delete(taskId);
    final subtasksToDelete = _subtaskBox.values.where((s) => s.taskId == taskId).toList();
    for (var s in subtasksToDelete) {
      await s.delete();
    }
  }

  // Subtask Operations
  Future<List<Subtask>> getSubtasks(String taskId) async {
    return _subtaskBox.values.where((s) => s.taskId == taskId).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  Future<Subtask> createSubtask(Subtask subtask) async {
    subtask.id ??= _uuid.v4();
    await _subtaskBox.put(subtask.id, subtask);
    return subtask;
  }

  Future<void> updateSubtask(Subtask subtask) async {
    await subtask.save();
  }

  Future<void> deleteSubtask(String subtaskId) async {
    await _subtaskBox.delete(subtaskId);
  }

  // Note Operations
  Future<List<Note>> getNotes() async {
    final userId = currentUserId;
    return _noteBox.values.where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<Note> createNote(Note note) async {
    note.id ??= _uuid.v4();
    note.userId = currentUserId;
    await _noteBox.put(note.id, note);
    return note;
  }

  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    await note.save();
  }

  Future<void> deleteNote(String noteId) async {
    await _noteBox.delete(noteId);
  }

  Future<void> deleteAllTasks() async {
    final userId = currentUserId;
    final tasksToDelete = _taskBox.values.where((t) => t.userId == userId).toList();
    for (var t in tasksToDelete) {
      await deleteTask(t.id!);
    }
  }
}
