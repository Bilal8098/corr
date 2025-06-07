// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cv_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CVDocumentAdapter extends TypeAdapter<CVDocument> {
  @override
  final int typeId = 0;

  @override
  CVDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CVDocument(
      id: fields[0] as String,
      data: (fields[1] as Map).cast<String, dynamic>(),
      lastUpdated: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CVDocument obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CVDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
