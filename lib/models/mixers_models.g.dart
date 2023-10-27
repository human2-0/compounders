// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixers_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MixerAdapter extends TypeAdapter<Mixer> {
  @override
  final int typeId = 2;

  @override
  Mixer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mixer(
      mixerId: fields[0] as String,
      assignedProducts: (fields[1] as Map).cast<String, AssignedProduct>(),
      lastUpdated: fields[2] as DateTime,
      shift: fields[3] as String,
      mixerName: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Mixer obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.mixerId)
      ..writeByte(1)
      ..write(obj.assignedProducts)
      ..writeByte(2)
      ..write(obj.lastUpdated)
      ..writeByte(3)
      ..write(obj.shift)
      ..writeByte(5)
      ..write(obj.mixerName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MixerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
