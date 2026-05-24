import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/hive_service.dart';
import '../models/task.dart';
import '../widgets/create_task_modal.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/calendar_widgets.dart';
import '../services/notification_service.dart';
import 'profile_screen.dart';
import 'rough_notes_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool isTodaySelected = true;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late DateTime _now;
  List<Task> _tasks = [];
  bool _isLoadingTasks = true;
  String _searchQuery = "";
  final _searchController = TextEditingController();
  late Timer _timer;
  int _notesCount = 0;
  String _userName = 'User';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  Route _createPremiumRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fetchTasks();
    _fetchNotesCount();
  }

  Future<void> _loadUser() async {
    final user = await HiveService().currentUser;
    if (user != null && mounted) {
      setState(() => _userName = user.name.split(' ')[0]);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Future<void> _fetchNotesCount() async {
    try {
      final notes = await HiveService().getNotes();
      if (mounted) setState(() => _notesCount = notes.length);
    } catch (_) {}
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoadingTasks = true);
    _fadeController.reset();
    try {
      final tasks = await HiveService().getTasks(_selectedDay);
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoadingTasks = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTasks = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Error fetching tasks"), backgroundColor: Theme.of(context).primaryColor),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _markTaskAsDone(Task task) async {
    NotificationService().cancelTask(task);
    task.isCompleted = true;
    await HiveService().updateTask(task);
    _fetchTasks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("✅  Task completed!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF1E1E2E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: "Undo",
        textColor: Theme.of(context).primaryColor,
        onPressed: () async {
          task.isCompleted = false;
          await HiveService().updateTask(task);
          NotificationService().scheduleTaskNotifications(task);
          _fetchTasks();
        },
      ),
    ));
  }

  void _deleteTask(Task task) async {
    NotificationService().cancelTask(task);
    await HiveService().deleteTask(task.id!);
    _fetchTasks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("🗑️  Task deleted", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF1E1E2E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: "Undo",
        textColor: Theme.of(context).primaryColor,
        onPressed: () async {
          await HiveService().createTask(task);
          _fetchTasks();
        },
      ),
    ));
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
              color: Theme.of(context).primaryColor,
              onRefresh: () async {
                await _fetchTasks();
                setState(() {
                  _focusedDay = DateTime.now();
                  if (isTodaySelected) _selectedDay = DateTime.now();
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────
                    _buildHeader(theme, isDark),
                    // ── Summary Card ────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: _buildSummaryCard(theme, isDark),
                    ),
                    const SizedBox(height: 24),
                    // ── Clock Card ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildClockCard(theme, isDark, is24, fmt),
                    ),
                    // ── Rough Notes preview ─────────────────
                    if (settings.get('showRoughNotes', defaultValue: false)) ...[
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _RoughNotesPreviewCard(count: _notesCount),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // ── Search + Tab row ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSearchAndTabs(theme, isDark),
                    ),
                    const SizedBox(height: 20),
                    // ── Calendar (if selected) ───────────────
                    if (!isTodaySelected) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
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
                                  _focusedDay = selected.month != _focusedDay.month ? selected : focused;
                                });
                                _fetchTasks();
                              },
                              onPageChanged: (focused) => setState(() => _focusedDay = focused),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // ── Tasks Section Header ─────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSectionHeader(theme),
                    ),
                    const SizedBox(height: 14),
                    // ── Tasks List ──────────────────────────
                    _buildTaskList(theme),
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

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_getGreeting()},",
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: theme.primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _headerIconBtn(
            icon: Icons.bar_chart_rounded,
            theme: theme,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, _createPremiumRoute(const StatsScreen()));
            },
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, _createPremiumRoute(const ProfileScreen()));
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconBtn({required IconData icon, required ThemeData theme, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 22),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isDark) {
    final total = _tasks.length;
    final done = _tasks.where((t) => t.isCompleted).length;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D0D0D), Color(0xFF3A3A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daily Progress",
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$done / $total  tasks done",
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    total == 0 ? "-" : "${(progress * 100).toInt()}%",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            progress == 1.0
                ? "🎉  All done! Excellent work!"
                : (progress > 0.5 ? "💪  Almost there, keep going!" : "🚀  Let's tick those tasks!"),
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildClockCard(ThemeData theme, bool isDark, bool is24, String fmt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM').format(_selectedDay),
                  style: TextStyle(fontSize: 13, color: theme.hintColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat(fmt).format(_now),
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor,
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (!is24) ...[
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          DateFormat('a').format(_now),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.hintColor),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  "LOCAL TIME",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: theme.hintColor.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "UTC  ${DateFormat('HH:mm').format(_now.toUtc())}",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndTabs(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500, fontSize: 15),
            decoration: InputDecoration(
              hintText: "Search tasks...",
              hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.6), fontWeight: FontWeight.normal),
              border: InputBorder.none,
              icon: Icon(Icons.search_rounded, color: theme.hintColor, size: 22),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                      child: Icon(Icons.close_rounded, color: theme.hintColor, size: 18),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Tab row
        Row(
          children: [
            _tabBtn("Today", isTodaySelected, theme, isDark, () {
              setState(() {
                isTodaySelected = true;
                _selectedDay = DateTime.now();
                _focusedDay = DateTime.now();
              });
              _fetchTasks();
            }),
            const SizedBox(width: 10),
            _tabBtn("Calendar", !isTodaySelected, theme, isDark, () {
              setState(() => isTodaySelected = false);
            }),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await showCreateTaskModal(context, _selectedDay);
                _fetchTasks();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.white, Colors.white.withValues(alpha: 0.8)]
                        : [const Color(0xFF0D0D0D), const Color(0xFF3A3A3A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : theme.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: isDark ? Colors.black : Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "Add Task",
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tabBtn(String label, bool isActive, ThemeData theme, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : theme.dividerColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? (isDark ? Colors.black : Colors.white)
                : theme.hintColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return Row(
      children: [
        Container(width: 4, height: 22, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(
          isTodaySelected ? "Upcoming Tasks" : "Tasks for ${DateFormat('d MMM').format(_selectedDay)}",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor),
        ),
        const Spacer(),
        if (_tasks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${_tasks.length}",
              style: const TextStyle(color: Color(0xFF0D0D0D), fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskList(ThemeData theme) {
    if (_isLoadingTasks) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF0D0D0D))),
      );
    }

    final filtered = _tasks.where((t) => t.title.toLowerCase().contains(_searchQuery)).toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 70),
        child: Center(
          child: Column(
            children: [
              const Text("📋", style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? "No tasks match your search" : "No tasks yet!",
                style: TextStyle(color: theme.hintColor, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isEmpty ? "Tap 'Add Task' to get started." : "Try a different keyword.",
                style: TextStyle(color: theme.hintColor.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildTaskItem(filtered[index]),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Padding(
      key: ValueKey(task.id ?? task.startDateTime.toIso8601String()),
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey("dismiss_${task.id}"),
        direction: DismissDirection.horizontal,
        background: _buildSwipeAction(
          color: Theme.of(context).primaryColor,
          icon: Icons.edit_rounded,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeAction(
          color: Theme.of(context).primaryColor,
          icon: Icons.delete_rounded,
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await showCreateTaskModal(context, _selectedDay, taskToEdit: task);
            _fetchTasks();
            return false;
          }
          return true;
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) _deleteTask(task);
        },
        child: TaskCard(
          task: task,
          backgroundColor: Theme.of(context).cardColor,
          onMarkDone: () => _markTaskAsDone(task),
        ),
      ),
    );
  }

  Widget _buildSwipeAction({required Color color, required IconData icon, required Alignment alignment}) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _RoughNotesPreviewCard extends StatelessWidget {
  final int count;
  const _RoughNotesPreviewCard({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (context, animation, secondaryAnimation) => const RoughNotesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = const Offset(0.0, 0.05);
              var end = Offset.zero;
              var curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
              );
            },
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0D0D0D), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rough Notes", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                  Text("$count ${count == 1 ? 'note' : 'notes'} saved", style: TextStyle(fontSize: 12, color: theme.hintColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
