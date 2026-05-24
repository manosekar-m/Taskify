import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../screens/focus_screen.dart';

class CapsuleButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const CapsuleButton({
    super.key,
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive
                ? (isDark ? Colors.black : Colors.white)
                : theme.primaryColor.withValues(alpha: 0.4),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.primaryColor, size: 22),
      ),
    );
  }
}

Widget _getTaskIconWidget(String title, Color color) {
  final t = title.toLowerCase();
  
  if (t.contains('call') || t.contains('phone')) return _buildIcon(Icons.phone_rounded, color);
  if (t.contains('home') || t.contains('house')) return _buildEmoji("🏠");
  if (t.contains('train') || t.contains('ticket')) return _buildEmoji("🚆");
  if (t.contains('flight') || t.contains('plane')) return _buildEmoji("✈️");
  if (t.contains('gym') || t.contains('workout')) return _buildEmoji("🏋️");
  if (t.contains('food') || t.contains('eat') || t.contains('lunch')) return _buildEmoji("🍴");
  if (t.contains('code') || t.contains('dev') || t.contains('laptop')) return _buildEmoji("💻");
  if (t.contains('study') || t.contains('book')) return _buildEmoji("📚");
  if (t.contains('meet') || t.contains('meeting')) return _buildEmoji("🤝");
  if (t.contains('money') || t.contains('pay') || t.contains('cash')) return _buildEmoji("💰");

  return _buildIcon(Icons.task_alt_rounded, color);
}

Widget _buildEmoji(String emoji) {
  return SizedBox(
    width: 26,
    height: 26,
    child: Center(
      child: Text(
        emoji, 
        style: const TextStyle(fontSize: 22, height: 1.1),
      ),
    ),
  );
}

Widget _buildIcon(IconData icon, Color color) {
  return Icon(icon, color: color, size: 24);
}

class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const BlinkingText({super.key, required this.text, required this.style});

  @override
  State<BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 0.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: Text(widget.text, style: widget.style));
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final Color backgroundColor;
  final VoidCallback onMarkDone;

  const TaskCard({
    super.key,
    required this.task,
    required this.backgroundColor,
    required this.onMarkDone,
  });

  DateTime _getEndDateTime() {
    if (task.endDateTime != null) return task.endDateTime!;
    try {
      final format = DateFormat('h:mm a');
      final endDtParsed = format.parse(task.endTime);
      var endDateTime = DateTime(
        task.startDateTime.year,
        task.startDateTime.month,
        task.startDateTime.day,
        endDtParsed.hour,
        endDtParsed.minute,
      );
      if (endDateTime.isBefore(task.startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
      return endDateTime;
    } catch (e) {
      return task.startDateTime.add(const Duration(hours: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = task.isCompleted;
    final now = DateTime.now();
    final endDateTime = _getEndDateTime();
    
    bool isLive = now.isAfter(task.startDateTime) && now.isBefore(endDateTime);

    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, box, _) {
        final bool is24Hours = box.get('is24Hours', defaultValue: false);
        final format = is24Hours ? DateFormat('HH:mm') : DateFormat('h:mm a');
        
        final startTimeStr = format.format(task.startDateTime);
        final endTimeStr = format.format(endDateTime);

        // Gradient configuration for the card border strip
        final List<Color> stripColors;
        if (isCompleted) {
          stripColors = isDark 
              ? [const Color(0xFF818CF8), const Color(0xFF6366F1)]
              : [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
        } else if (isLive) {
          stripColors = [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];
        } else {
          stripColors = isDark 
              ? [const Color(0xFF252545), const Color(0xFF1A1A35)]
              : [const Color(0xFFE8E8F4), const Color(0xFFF0F0FF)];
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Premium gradient border strip
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: stripColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.dividerColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: _getTaskIconWidget(task.title, isCompleted ? theme.colorScheme.secondary : theme.primaryColor),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: theme.primaryColor,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      decorationColor: theme.hintColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 12, color: theme.hintColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('d MMM').format(task.startDateTime),
                                        style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(Icons.access_time_rounded, size: 12, color: theme.hintColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$startTimeStr - $endTimeStr",
                                        style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildPriorityBadge(task.priority, isDark),
                                const SizedBox(height: 10),
                                _buildDoneButton(context, isCompleted),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildInfoChip(context, Icons.timer_outlined, task.duration),
                            const SizedBox(width: 8),
                            _buildInfoChip(context, Icons.label_outline_rounded, task.category ?? "General"),
                            const Spacer(),
                            if (!isCompleted)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  if (!context.mounted) return;
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 350),
                                      pageBuilder: (context, animation, secondaryAnimation) => FocusScreen(task: task),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.play_arrow_rounded, color: Color(0xFFF59E0B), size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        "Focus",
                                        style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w800, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (isLive && !isCompleted) ...[
                              const SizedBox(width: 10),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Text("LIVE", style: TextStyle(color: theme.colorScheme.secondary, fontSize: 9, fontWeight: FontWeight.w900)),
                            ],
                          ],
                        ),
                      ],
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

  Widget _buildPriorityBadge(String priority, bool isDark) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high': color = const Color(0xFFEF4444); break;
      case 'medium': color = const Color(0xFFF59E0B); break;
      case 'low': color = const Color(0xFF3B82F6); break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context, bool isCompleted) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onMarkDone();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isCompleted ? theme.colorScheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted ? theme.colorScheme.secondary : theme.dividerColor,
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: t.hintColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: t.hintColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
