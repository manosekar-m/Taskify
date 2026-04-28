import 'package:flutter/material.dart';
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
      onTap: onTap,
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.dividerColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.primaryColor, size: 24),
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
  return Icon(icon, color: color, size: 26);
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
    bool isPast = now.isAfter(endDateTime);

    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, box, _) {
        final bool is24Hours = box.get('is24Hours', defaultValue: false);
        final format = is24Hours ? DateFormat('HH:mm') : DateFormat('h:mm a');
        
        final startTimeStr = format.format(task.startDateTime);
        final endTimeStr = format.format(endDateTime);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : (isLive ? Colors.orange : theme.dividerColor),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: _getTaskIconWidget(task.title, theme.primaryColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted ? theme.hintColor : theme.primaryColor,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 12, color: theme.hintColor.withValues(alpha: 0.6)),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('d MMM').format(task.startDateTime),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme.hintColor.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(Icons.access_time_rounded, size: 12, color: theme.hintColor.withValues(alpha: 0.6)),
                                        const SizedBox(width: 4),
                                        Text(
                                          "$startTimeStr - $endTimeStr",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme.hintColor.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _buildDoneButton(context, isCompleted),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_outlined, size: 14, color: theme.hintColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      task.duration,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCompleted)
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => FocusScreen(task: task)),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_arrow_rounded, size: 14, color: Colors.orange),
                                        SizedBox(width: 4),
                                        Text(
                                          "Focus",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (isCompleted)
                                const Text(
                                  "DONE",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                )
                              else if (isLive)
                                const BlinkingText(
                                  text: "● LIVE",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                )
                              else if (isPast)
                                const Text(
                                  "OVERDUE",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                )
                              else
                                Text(
                                  "UPCOMING",
                                  style: TextStyle(
                                    color: theme.hintColor.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 1,
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
      }
    );
  }

  Widget _buildDoneButton(BuildContext context, bool isCompleted) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isCompleted ? null : onMarkDone,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted ? Colors.green : theme.dividerColor,
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
