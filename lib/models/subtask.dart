import 'package:hive/hive.dart';

part 'subtask.g.dart';

@HiveType(typeId: 1)
class Subtask extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  String title;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  double position;

  Subtask({
    this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.position = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted,
      'position': position,
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'],
      taskId: json['task_id'],
      title: json['title'],
      isCompleted: json['is_completed'] ?? false,
      position: (json['position'] ?? 0.0).toDouble(),
    );
  }
}
