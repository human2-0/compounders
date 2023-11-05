// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'used_amount_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsedAmountDataAdapter extends TypeAdapter<UsedAmountData> {
  @override
  final int typeId = 7;

  @override
  UsedAmountData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UsedAmountData(
      date: fields[0] as String,
      usedAmount: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, UsedAmountData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.usedAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsedAmountDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
