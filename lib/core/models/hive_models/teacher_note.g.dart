// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TeacherNoteAdapter extends TypeAdapter<TeacherNote> {
  @override
  final int typeId = 0;

  @override
  TeacherNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TeacherNote(
      id: fields[0] as String,
      folderId: fields[1] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      linkedBookAccessionNo: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TeacherNote obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.folderId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.linkedBookAccessionNo)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
