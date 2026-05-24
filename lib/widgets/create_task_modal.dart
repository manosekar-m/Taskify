import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/notification_service.dart';
import '../services/hive_service.dart';
import 'custom_widgets.dart';

Future<void> showCreateTaskModal(BuildContext context, DateTime initialDate, {Task? taskToEdit, String? initialTimeStr}) async {
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
  String selectedPriority = taskToEdit?.priority ?? 'Medium';
  String? selectedCategory = taskToEdit?.category;
  bool isRecurring = taskToEdit?.isRecurring ?? false;
  String? recurrencePattern = taskToEdit?.recurrencePattern;
  List<Subtask> subtasks = [];
  bool isLoadingSubtasks = false;
  final stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;

  final categories = ['Work', 'Personal', 'Shopping', 'Health', 'Finance', 'Other'];
  final priorities = ['Low', 'Medium', 'High'];
  final recurrencePatterns = ['Daily', 'Weekly', 'Monthly'];

  await showModalBottomSheet(
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
            // Helper functions moved out of the dynamic build loop where possible
            void onTimePicked(bool isStart, TimeOfDay picked) {
              setModalState(() {
                if (isStart) {
                  startTime = picked;
                } else {
                  endTime = picked;
                }
                
                if (startTime != null && endTime != null) {
                  final startMinutes = startTime!.hour * 60 + startTime!.minute;
                  var endMinutes = endTime!.hour * 60 + endTime!.minute;
                  if (endMinutes < startMinutes) endMinutes += 24 * 60;
                  final diff = endMinutes - startMinutes;
                  final hours = diff ~/ 60;
                  final minutes = diff % 60;
                  durationStr = hours > 0 ? "$hours hr ${minutes > 0 ? '$minutes min' : ''}" : "$minutes Min";
                }
              });
            }

            Future<void> pickTime(bool isStart) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: isStart ? (startTime ?? TimeOfDay.now()) : (endTime ?? TimeOfDay.now()),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData(
                      useMaterial3: true,
                      brightness: theme.brightness,
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: theme.primaryColor,
                        brightness: theme.brightness,
                        primary: theme.primaryColor,
                        onPrimary: isDark ? Colors.black : Colors.white,
                        surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        onSurface: theme.primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) onTimePicked(isStart, picked);
            }

            if (taskToEdit != null && subtasks.isEmpty && !isLoadingSubtasks) {
              isLoadingSubtasks = true;
              HiveService().getSubtasks(taskToEdit.id!).then((list) {
                if (modalContext.mounted) {
                  setModalState(() {
                    subtasks = list;
                    isLoadingSubtasks = false;
                  });
                }
              });
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
                  Row(
                    children: [
                      Expanded(child: _buildLightTextField(modalContext, titleController, "Task Title (e.g. Sync)")),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          if (!isListening) {
                            bool available = await speech.initialize();
                            if (available) {
                              setModalState(() => isListening = true);
                              speech.listen(onResult: (val) {
                                setModalState(() {
                                  titleController.text = val.recognizedWords;
                                  if (val.finalResult) isListening = false;
                                });
                              });
                            }
                          } else {
                            setModalState(() => isListening = false);
                            speech.stop();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isListening ? const Color(0xFFEF4444) : theme.primaryColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: isListening ? [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 4,
                              )
                            ] : [],
                          ),
                          child: Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            color: isListening ? Colors.white : (isDark ? Colors.black : Colors.white),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (initialTimeStr == null) ...[
                    const SizedBox(height: 25),
                    _buildInputLabel(modalContext, "Date"),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData(
                                useMaterial3: true,
                                brightness: theme.brightness,
                                colorScheme: ColorScheme.fromSeed(
                                  seedColor: theme.primaryColor,
                                  brightness: theme.brightness,
                                  primary: theme.primaryColor,
                                  onPrimary: isDark ? Colors.black : Colors.white,
                                  surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                  onSurface: theme.primaryColor,
                                ),
                                dialogTheme: DialogThemeData(
                                  backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                ),
                                datePickerTheme: DatePickerThemeData(
                                  headerBackgroundColor: isDark ? const Color(0xFF2C2C2E) : theme.primaryColor.withValues(alpha: 0.1),
                                  headerForegroundColor: theme.primaryColor,
                                  backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                  dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) return theme.primaryColor;
                                    return null;
                                  }),
                                  dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return isDark ? Colors.black : Colors.white;
                                    }
                                    return theme.primaryColor;
                                  }),
                                  todayBorder: BorderSide(color: theme.primaryColor, width: 2),
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
                                child: _buildTimeBox(modalContext, formatTimeDisplay(startTime), Icons.access_time_rounded),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Container(
                            width: 20,
                            height: 2,
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel(modalContext, "End Time"),
                              GestureDetector(
                                onTap: () => pickTime(false),
                                child: _buildTimeBox(modalContext, formatTimeDisplay(endTime), Icons.access_time_filled_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel(modalContext, "Priority"),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: theme.dividerColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPriority,
                                  isExpanded: true,
                                  items: priorities.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                                  )).toList(),
                                  onChanged: (val) => setModalState(() => selectedPriority = val!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel(modalContext, "Category"),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: theme.dividerColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCategory,
                                  hint: Text("None", style: TextStyle(color: theme.hintColor)),
                                  isExpanded: true,
                                  items: categories.map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                                  )).toList(),
                                  onChanged: (val) => setModalState(() => selectedCategory = val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputLabel(modalContext, "Recurring Task"),
                      Switch(
                        value: isRecurring,
                        onChanged: (val) => setModalState(() => isRecurring = val),
                        activeThumbColor: theme.primaryColor,
                      ),
                    ],
                  ),
                  if (isRecurring)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: recurrencePattern,
                          hint: Text("Select Frequency", style: TextStyle(color: theme.hintColor)),
                          isExpanded: true,
                          items: recurrencePatterns.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                          )).toList(),
                          onChanged: (val) => setModalState(() => recurrencePattern = val),
                        ),
                      ),
                    ),

                  const SizedBox(height: 25),
                  _buildInputLabel(modalContext, "Subtasks"),
                  if (isLoadingSubtasks)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: [
                        ...subtasks.map((s) => Row(
                          children: [
                            Checkbox(
                              value: s.isCompleted,
                              onChanged: (val) {
                                setModalState(() => s.isCompleted = val!);
                                if (s.id != null) {
                                  HiveService().updateSubtask(s);
                                }
                              },
                              activeColor: theme.primaryColor,
                            ),
                            Expanded(child: Text(s.title, style: TextStyle(color: theme.primaryColor))),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setModalState(() => subtasks.remove(s));
                                HiveService().deleteSubtask(s.id!);
                              },
                            ),
                          ],
                        )),
                        TextButton.icon(
                          onPressed: () async {
                            final controller = TextEditingController();
                            await showDialog(
                              context: modalContext,
                              builder: (context) => AlertDialog(
                                title: const Text("New Subtask"),
                                content: TextField(controller: controller, autofocus: true),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                  TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Add")),
                                ],
                              ),
                            ).then((val) async {
                              if (val != null && val.toString().isNotEmpty) {
                                final s = Subtask(taskId: taskToEdit?.id ?? '', title: val.toString());
                                if (taskToEdit != null) {
                                  final saved = await HiveService().createSubtask(s);
                                  setModalState(() => subtasks.add(saved));
                                } else {
                                  setModalState(() => subtasks.add(s));
                                }
                              }
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Subtask"),
                        ),
                      ],
                    ),
                  
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

                        if (startDt.isBefore(DateTime.now()) && taskToEdit == null) {
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            const SnackBar(
                              content: Text("Cannot create tasks in the past", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.black,
                              duration: Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        final sTimeStr = DateFormat('h:mm a').format(startDt);
                        final eTimeStr = DateFormat('h:mm a').format(endDt);

                        if (taskToEdit == null) {
                          final newTask = Task(
                            title: titleController.text,
                            startTime: sTimeStr,
                            endTime: eTimeStr,
                            duration: durationStr,
                            colorIndex: DateTime.now().millisecond % 5,
                            startDateTime: startDt,
                            endDateTime: endDt,
                            priority: selectedPriority,
                            category: selectedCategory,
                            isRecurring: isRecurring,
                            recurrencePattern: recurrencePattern,
                          );
                          final savedTask = await HiveService().createTask(newTask);
                          // Save subtasks if any
                          for (var s in subtasks) {
                            s.taskId = savedTask.id!;
                            await HiveService().createSubtask(s);
                          }
                          NotificationService().scheduleTaskNotifications(savedTask);
                        } else {
                          NotificationService().cancelTask(taskToEdit);
                          taskToEdit.title = titleController.text;
                          taskToEdit.startTime = sTimeStr;
                          taskToEdit.endTime = eTimeStr;
                          taskToEdit.duration = durationStr;
                          taskToEdit.startDateTime = startDt;
                          taskToEdit.endDateTime = endDt;
                          taskToEdit.priority = selectedPriority;
                          taskToEdit.category = selectedCategory;
                          taskToEdit.isRecurring = isRecurring;
                          taskToEdit.recurrencePattern = recurrencePattern;
                          
                          await HiveService().updateTask(taskToEdit);
                          // Subtasks are handled individually or we can sync them here
                          NotificationService().scheduleTaskNotifications(taskToEdit);
                        }
                        if (modalContext.mounted) Navigator.pop(modalContext);
                      } else {
                        ScaffoldMessenger.of(modalContext).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all details to proceed"),
                            backgroundColor: Color(0xFF1A1A1A),
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: theme.dividerColor.withValues(alpha: 0.4),
        width: 1.5,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: theme.primaryColor.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: theme.primaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}
