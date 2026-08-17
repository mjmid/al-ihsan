// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_folder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteFolderAdapter extends TypeAdapter<NoteFolder> {
  @override
  final int typeId = 1;

  @override
  NoteFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteFolder(
      id: fields[0] as String,
      name: fields[1] as String,
      colorHex: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NoteFolder obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorHex)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteFolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
