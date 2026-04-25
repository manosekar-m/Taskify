import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import 'custom_widgets.dart';

void showCreateTaskModal(BuildContext context, DateTime initialDate, {Task? taskToEdit, String? initialTimeStr}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final settingsBox = Hive.box('settings');
  final is24Hours = settingsBox.get('is24Hours', defaultValue: false);
  
  final TextEditingController titleController = TextEditingController(text: taskToEdit?.title);
  DateTime selectedDate = taskToEdit?.startDateTime ?? initialDate;
  
  TimeOfDay? parseTimeString(String? timeString) {
    if (timeString == null || timeString == "Select Time") return null;
    try {
      final format12 = DateFormat('h:mm a');
      final dt = format12.parse(timeString.toUpperCase());
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (e) {
      try {
        final format24 = DateFormat('HH:mm');
        final dt = format24.parse(timeString);
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (e) {
        try {
           final format = DateFormat('h a');
           final dt = format.parse(timeString.toUpperCase());
           return TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (e) {
          return null;
        }
      }
    }
  }

  TimeOfDay? startTime = parseTimeString(initialTimeStr ?? taskToEdit?.startTime);
  TimeOfDay? endTime = parseTimeString(taskToEdit?.endTime);
  
  if (initialTimeStr != null && startTime != null && endTime == null) {
    int endHour = (startTime.hour + 1) % 24;
    endTime = TimeOfDay(hour: endHour, minute: startTime.minute);
  }

  String durationStr = taskToEdit?.duration ?? (initialTimeStr != null ? "1 hr" : "0 Min");

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) {
      return Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 30,
          right: 30,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (modalContext, setModalState) {
            void calculateDuration() {
              if (startTime != null && endTime != null) {
                final startMinutes = startTime!.hour * 60 + startTime!.minute;
                var endMinutes = endTime!.hour * 60 + endTime!.minute;

                if (endMinutes < startMinutes) {
                  endMinutes += 24 * 60;
                }

                final diff = endMinutes - startMinutes;
                final hours = diff ~/ 60;
                final minutes = diff % 60;

                if (hours > 0) {
                  durationStr = "$hours hr ${minutes > 0 ? '$minutes min' : ''}";
                } else {
                  durationStr = "$minutes Min";
                }
              }
            }

            Future<void> pickTime(bool isStart) async {
              final picked = await showTimePicker(
                context: context, // Use root context for full screen constraints
                initialTime: isStart ? (startTime ?? TimeOfDay.now()) : (endTime ?? TimeOfDay.now()),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData(
                      useMaterial3: true,
                      brightness: theme.brightness,
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.blue,
                        brightness: theme.brightness,
                        primary: Colors.blue,
                        onPrimary: Colors.white,
                        surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        onSurface: theme.primaryColor,
                      ),
                      dialogTheme: DialogThemeData(
                        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      timePickerTheme: TimePickerThemeData(
                        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        hourMinuteColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05),
                        hourMinuteTextColor: theme.primaryColor,
                        dialBackgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05),
                        dialHandColor: Colors.blue,
                        dialTextColor: theme.primaryColor,
                        entryModeIconColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    ),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                      child: child!,
                    ),
                  );
                },
              );
              if (picked != null) {
                setModalState(() {
                  if (isStart) {
                    startTime = picked;
                  } else {
                    endTime = picked;
                  }
                  calculateDuration();
                });
              }
            }

            String formatTimeDisplay(TimeOfDay? time) {
              if (time == null) return "Select Time";
              final now = DateTime.now();
              final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
              return DateFormat(is24Hours ? 'HH:mm' : 'h:mm a').format(dt);
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    initialTimeStr != null 
                        ? "Add task for $initialTimeStr"
                        : (taskToEdit == null ? "Create New Task" : "Edit Task"),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildInputLabel(modalContext, "Task Title"),
                  _buildLightTextField(modalContext, titleController, "Task Title (e.g. Sync)"),
                  
                  if (initialTimeStr == null) ...[
                    const SizedBox(height: 25),
                    _buildInputLabel(modalContext, "Date"),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData(
                                useMaterial3: true,
                                brightness: theme.brightness,
                                colorScheme: ColorScheme.fromSeed(
                                  seedColor: Colors.blue,
                                  brightness: theme.brightness,
                                  primary: Colors.blue,
                                  onPrimary: Colors.white,
                                  surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                  onSurface: theme.primaryColor,
                                ),
                                dialogTheme: DialogThemeData(
                                  backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                ),
                                datePickerTheme: DatePickerThemeData(
                                  headerBackgroundColor: Colors.blue,
                                  headerForegroundColor: Colors.white,
                                  backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                  dayForegroundColor: WidgetStateProperty.all(theme.primaryColor),
                                  todayForegroundColor: WidgetStateProperty.all(Colors.blue),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) setModalState(() => selectedDate = picked);
                      },
                      child: _buildTimeBox(modalContext, DateFormat('EEEE, dd MMMM yyyy').format(selectedDate), Icons.calendar_today_outlined),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel(modalContext, "Start Time"),
                              GestureDetector(
                                onTap: () => pickTime(true),
                                child: _buildTimeBox(modalContext, formatTimeDisplay(startTime), Icons.access_time),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel(modalContext, "End Time"),
                              GestureDetector(
                                onTap: () => pickTime(false),
                                child: _buildTimeBox(modalContext, formatTimeDisplay(endTime), Icons.access_time_filled),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  TaskifyButton(
                    text: taskToEdit == null ? "Add Task" : "Update Task",
                    onPressed: () async {
                      if (titleController.text.isNotEmpty && startTime != null && endTime != null) {
                        final startDt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startTime!.hour, startTime!.minute);
                        var endDt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endTime!.hour, endTime!.minute);
                        
                        if (endDt.isBefore(startDt)) {
                          endDt = endDt.add(const Duration(days: 1));
                        }

                        final tasksBox = Hive.box<Task>('tasks');
                        
                        final sTimeStr = DateFormat('h:mm a').format(startDt);
                        final eTimeStr = DateFormat('h:mm a').format(endDt);

                        if (taskToEdit == null) {
                          final newTask = Task(
                            title: titleController.text,
                            startTime: sTimeStr,
                            endTime: eTimeStr,
                            duration: durationStr,
                            colorIndex: tasksBox.length % 5,
                            startDateTime: startDt,
                            endDateTime: endDt,
                          );
                          tasksBox.add(newTask);
                          NotificationService().scheduleTaskNotifications(newTask);
                        } else {
                          taskToEdit.title = titleController.text;
                          taskToEdit.startTime = sTimeStr;
                          taskToEdit.endTime = eTimeStr;
                          taskToEdit.duration = durationStr;
                          taskToEdit.startDateTime = startDt;
                          taskToEdit.endDateTime = endDt;
                          await taskToEdit.save();
                          NotificationService().scheduleTaskNotifications(taskToEdit);
                        }
                        if (modalContext.mounted) Navigator.pop(modalContext);
                      } else {
                        ScaffoldMessenger.of(modalContext).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all details to proceed"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Widget _buildInputLabel(BuildContext context, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 5),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).hintColor,
      ),
    ),
  );
}

Widget _buildLightTextField(BuildContext context, TextEditingController controller, String hint) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    decoration: BoxDecoration(
      color: theme.dividerColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: TextField(
      controller: controller,
      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(fontWeight: FontWeight.w500, color: theme.hintColor.withValues(alpha: 0.5)),
      ),
    ),
  );
}

Widget _buildTimeBox(BuildContext context, String time, IconData icon) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: theme.dividerColor.withValues(alpha: 0.5),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.primaryColor,
          ),
        ),
        const Spacer(),
        Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: theme.hintColor.withValues(alpha: 0.5)),
      ],
    ),
  );
}
