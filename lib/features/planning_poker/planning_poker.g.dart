// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_poker.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanningDataAdapter extends TypeAdapter<PlanningData> {
  @override
  final int typeId = 0;

  @override
  PlanningData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanningData(
      id: fields[0] as String,
      name: fields[1] as String,
      invitationCode: fields[2] as String,
      createDate: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PlanningData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.invitationCode)
      ..writeByte(3)
      ..write(obj.createDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanningDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
