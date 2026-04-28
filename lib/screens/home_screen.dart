import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../widgets/create_task_modal.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/calendar_widgets.dart';
import '../services/notification_service.dart';
import 'profile_screen.dart';
import 'rough_notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isTodaySelected = true;
  late Timer _timer;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _markTaskAsDone(Task task) {
    task.isCompleted = true;
    task.save();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Task completed",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "Undo",
          textColor: Colors.white,
          onPressed: () {
            task.isCompleted = false;
            task.save();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      if (task.isInBox && task.isCompleted) {
        task.delete();
      }
    });
  }

  void _deleteTask(Task task) async {
    final tasksBox = Hive.box<Task>('tasks');
    
    final taskData = {
      'title': task.title,
      'startTime': task.startTime,
      'endTime': task.endTime,
      'duration': task.duration,
      'colorIndex': task.colorIndex,
      'startDateTime': task.startDateTime,
      'isCompleted': task.isCompleted,
      'endDateTime': task.endDateTime,
    };
    
    NotificationService().cancelTask(task);
    await task.delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Task deleted",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "Undo",
          textColor: Colors.white,
          onPressed: () {
            tasksBox.add(Task(
              title: taskData['title'] as String,
              startTime: taskData['startTime'] as String,
              endTime: taskData['endTime'] as String,
              duration: taskData['duration'] as String,
              colorIndex: taskData['colorIndex'] as int,
              startDateTime: taskData['startDateTime'] as DateTime,
              isCompleted: taskData['isCompleted'] as bool,
              endDateTime: taskData['endDateTime'] as DateTime?,
            ));
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsBox = Hive.box('settings');

    return ValueListenableBuilder<Box>(
      valueListenable: settingsBox.listenable(),
      builder: (context, settings, _) {
        final bool is24 = settings.get('is24Hours', defaultValue: false);
        final String fmt = is24 ? 'HH:mm' : 'h:mm';
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _focusedDay = DateTime.now();
                  if (isTodaySelected) _selectedDay = DateTime.now();
                });
              },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back!",
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Your Schedule",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.dividerColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.dividerColor,
                          child: Icon(Icons.person_outline, color: theme.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    CapsuleButton(
                      text: "Today",
                      isActive: isTodaySelected,
                      onTap: () => setState(() {
                        isTodaySelected = true;
                        _selectedDay = DateTime.now();
                        _focusedDay = DateTime.now();
                      }),
                    ),
                    const SizedBox(width: 12),
                    CapsuleButton(
                      text: "Calendar",
                      isActive: !isTodaySelected,
                      onTap: () => setState(() => isTodaySelected = false),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => showCreateTaskModal(context, _selectedDay),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: isDark ? Colors.black : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                if (isTodaySelected) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                              ? [const Color(0xFF1C1C1E), const Color(0xFF0D0D0D)]
                              : [Colors.white, const Color(0xFFF0F0F0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE').format(_selectedDay),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('d MMMM').format(_selectedDay),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: theme.hintColor.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat(fmt).format(_now.toUtc()),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    if (!is24)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          DateFormat('a').format(_now.toUtc()),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.hintColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                    Text(
                                      "GLOBAL (UTC)",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat(fmt).format(_now),
                                      style: TextStyle(
                                        fontSize: 60,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    if (!is24)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12, left: 5),
                                        child: Text(
                                          DateFormat('a').format(_now),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: theme.hintColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    "LOCAL TIME",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: theme.hintColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                          ),
                      if (settings.get('showRoughNotes', defaultValue: false)) ...[
                        const SizedBox(height: 25),
                        _RoughNotesPreviewCard(),
                      ],
                    ],
                  ),
                ] else ...[
                  CalendarHeader(
                    focusedMonth: _focusedDay,
                    onLeftChevronTap: () => setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    }),
                    onRightChevronTap: () => setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    }),
                  ),
                  const SizedBox(height: 10),
                  OldCalendarView(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        // Redirect to next/previous month if a date from that month is selected
                        if (selected.month != _focusedDay.month) {
                          _focusedDay = selected;
                        } else {
                          _focusedDay = focused;
                        }
                      });
                    },
                    onPageChanged: (focused) {
                      setState(() {
                        _focusedDay = focused;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 40),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isTodaySelected ? "All Upcoming Tasks" : "Tasks for ${DateFormat('d MMM').format(_selectedDay)}",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                ValueListenableBuilder<Box<Task>>(
                  valueListenable: Hive.box<Task>('tasks').listenable(),
                  builder: (context, box, _) {
                    final allTasks = box.values.toList();
                    final tasks = isTodaySelected 
                        ? allTasks.where((task) => task.startDateTime.isAfter(DateTime.now().subtract(const Duration(hours: 2)))).toList()
                        : allTasks.where((task) => DateUtils.isSameDay(task.startDateTime, _selectedDay)).toList();
                    
                    tasks.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
                    
                    if (tasks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          child: Column(
                            children: [
                              Icon(Icons.auto_awesome_outlined, size: 60, color: theme.dividerColor),
                              const SizedBox(height: 15),
                              Text(
                                "No tasks found!",
                                style: TextStyle(color: theme.hintColor, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Dismissible(
                            key: ValueKey(task.key ?? "${task.startDateTime.toIso8601String()}_${task.title}"),
                            direction: DismissDirection.horizontal,
                            background: _buildSwipeAction(
                              color: theme.primaryColor,
                              icon: Icons.edit_rounded,
                              alignment: Alignment.centerLeft,
                            ),
                            secondaryBackground: _buildSwipeAction(
                              color: Colors.red,
                              icon: Icons.delete_rounded,
                              alignment: Alignment.centerRight,
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                showCreateTaskModal(context, _selectedDay, taskToEdit: task);
                                return false;
                              }
                              return true;
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                _deleteTask(task);
                              }
                            },
                            child: TaskCard(
                              task: task,
                              backgroundColor: theme.cardColor,
                              onMarkDone: () => _markTaskAsDone(task),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
  }

  Widget _buildSwipeAction({required Color color, required IconData icon, required Alignment alignment}) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _RoughNotesPreviewCard extends StatelessWidget {
  const _RoughNotesPreviewCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = Hive.box('settings');
    final raw = box.get('roughNotesList');
    final notes = (raw is List)
        ? List<Map<String, dynamic>>.from(
            raw.map((e) => Map<String, dynamic>.from(e as Map)))
        : <Map<String, dynamic>>[];

    final count = notes.length;
    final previewContent = count > 0 ? (notes.first['content'] as String? ?? '') : '';
    final previewTitle  = count > 0 ? (notes.first['title']   as String? ?? 'Untitled') : '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoughNotesScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: theme.dividerColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: theme.primaryColor),
                const SizedBox(width: 10),
                Text(
                  'Rough Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count ${count == 1 ? "note" : "notes"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: theme.hintColor),
              ],
            ),
            if (count > 0) ...[
              const SizedBox(height: 14),
              Text(
                previewTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
              if (previewContent.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  previewContent,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.hintColor,
                    height: 1.4,
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Tap to add your rough notes...',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.hintColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
