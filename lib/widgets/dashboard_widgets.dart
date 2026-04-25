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
    bool isFuture = now.isBefore(task.startDateTime);
    bool isPast = now.isAfter(endDateTime);

    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(keys: ['is24Hours']),
      builder: (context, box, _) {
        final bool is24Hours = box.get('is24Hours', defaultValue: false);
        final format = is24Hours ? DateFormat('HH:mm') : DateFormat('h:mm a');
        
        final startTimeStr = format.format(task.startDateTime);
        final endTimeStr = format.format(endDateTime);

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    color: isCompleted ? Colors.green : (isLive ? Colors.orange : theme.dividerColor),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: isCompleted 
                                    ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
                                    : _getTaskIconWidget(task.title, theme.primaryColor),
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted ? theme.hintColor : theme.primaryColor,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: theme.hintColor.withValues(alpha: 0.8)),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('dd MMM').format(task.startDateTime),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: theme.hintColor.withValues(alpha: 0.8),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.access_time, size: 14, color: theme.hintColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          "$startTimeStr - $endTimeStr",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: theme.hintColor,
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
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              // Left — Duration badge
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.timer_outlined, size: 16, color: theme.hintColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          task.duration,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: theme.hintColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Center — Focus button
                              if (!isCompleted)
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => FocusScreen(task: task)),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_arrow_rounded, size: 16, color: Colors.orange),
                                        SizedBox(width: 4),
                                        Text(
                                          "Focus",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Right — Status label
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: !isCompleted
                                      ? (isLive
                                          ? const BlinkingText(
                                              text: "● LIVE",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
                                                letterSpacing: 0.5,
                                              ),
                                            )
                                          : isFuture
                                              ? Text(
                                                  "LATER",
                                                  style: TextStyle(
                                                    color: theme.hintColor.withValues(alpha: 0.6),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                    letterSpacing: 0.5,
                                                  ),
                                                )
                                              : isPast
                                                  ? const Text(
                                                      "DONE",
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 12,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    )
                                                  : const SizedBox.shrink())
                                      : const SizedBox.shrink(),
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
