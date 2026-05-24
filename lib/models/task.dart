import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String startTime;

  @HiveField(2)
  String endTime;

  @HiveField(3)
  String duration;

  @HiveField(4)
  int colorIndex;

  @HiveField(5)
  DateTime startDateTime;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime? endDateTime;

  @HiveField(8)
  String? id;

  @HiveField(9)
  String? userId;

  @HiveField(10)
  String? description;

  @HiveField(11)
  String priority; // 'Low', 'Medium', 'High'

  @HiveField(12)
  String? category;

  @HiveField(13)
  bool isRecurring;

  @HiveField(14)
  String? recurrencePattern; // 'Daily', 'Weekly', 'Monthly'

  @HiveField(15)
  double position;

  Task({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.colorIndex,
    required this.startDateTime,
    this.isCompleted = false,
    this.endDateTime,
    this.id,
    this.userId,
    this.description,
    this.priority = 'Medium',
    this.category,
    this.isRecurring = false,
    this.recurrencePattern,
    this.position = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startDateTime.toIso8601String(),
      'end_time': endDateTime?.toIso8601String(),
      'start_time_str': startTime,
      'end_time_str': endTime,
      'duration': duration,
      'color_index': colorIndex,
      'is_completed': isCompleted,
      'priority': priority,
      'category': category,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'position': position,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      startDateTime: DateTime.parse(json['start_time']),
      endDateTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      startTime: json['start_time_str'],
      endTime: json['end_time_str'],
      duration: json['duration'],
      colorIndex: json['color_index'],
      isCompleted: json['is_completed'],
      priority: json['priority'] ?? 'Medium',
      category: json['category'],
      isRecurring: json['is_recurring'] ?? false,
      recurrencePattern: json['recurrence_pattern'],
      position: (json['position'] ?? 0.0).toDouble(),
    );
  }
}
