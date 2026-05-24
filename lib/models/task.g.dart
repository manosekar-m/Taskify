// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      title: fields[0] as String,
      startTime: fields[1] as String,
      endTime: fields[2] as String,
      duration: fields[3] as String,
      colorIndex: fields[4] as int,
      startDateTime: fields[5] as DateTime,
      isCompleted: fields[6] as bool,
      endDateTime: fields[7] as DateTime?,
      id: fields[8] as String?,
      userId: fields[9] as String?,
      description: fields[10] as String?,
      priority: fields[11] as String,
      category: fields[12] as String?,
      isRecurring: fields[13] as bool,
      recurrencePattern: fields[14] as String?,
      position: fields[15] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.colorIndex)
      ..writeByte(5)
      ..write(obj.startDateTime)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.endDateTime)
      ..writeByte(8)
      ..write(obj.id)
      ..writeByte(9)
      ..write(obj.userId)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.priority)
      ..writeByte(12)
      ..write(obj.category)
      ..writeByte(13)
      ..write(obj.isRecurring)
      ..writeByte(14)
      ..write(obj.recurrencePattern)
      ..writeByte(15)
      ..write(obj.position);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
