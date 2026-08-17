// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineEntryAdapter extends TypeAdapter<RoutineEntry> {
  @override
  final int typeId = 2;

  @override
  RoutineEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineEntry(
      id: fields[0] as String,
      daysOfWeek: (fields[9] as List).cast<int>(),
      startTime: fields[2] as String,
      endTime: fields[3] as String,
      subjectName: fields[4] as String,
      className: fields[5] as String,
      roomNumber: fields[10] as String?,
      reminderMinutes: fields[11] as int?,
      nightBeforeAlarm: fields[12] as bool,
      nightBeforeAlarmTime: fields[13] as String?,
      linkedBookAccessionNo: fields[6] as String?,
      linkedBookName: fields[7] as String?,
      notes: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RoutineEntry obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.subjectName)
      ..writeByte(5)
      ..write(obj.className)
      ..writeByte(6)
      ..write(obj.linkedBookAccessionNo)
      ..writeByte(7)
      ..write(obj.linkedBookName)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.daysOfWeek)
      ..writeByte(10)
      ..write(obj.roomNumber)
      ..writeByte(11)
      ..write(obj.reminderMinutes)
      ..writeByte(12)
      ..write(obj.nightBeforeAlarm)
      ..writeByte(13)
      ..write(obj.nightBeforeAlarmTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
