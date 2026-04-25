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

  Task({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.colorIndex,
    required this.startDateTime,
    this.isCompleted = false,
    this.endDateTime,
  });
}
