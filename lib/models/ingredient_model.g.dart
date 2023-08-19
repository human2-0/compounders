// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IngredientStateAdapter extends TypeAdapter<IngredientState> {
  @override
  final int typeId = 0;

  @override
  IngredientState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientState(
      stock: fields[0] as double,
      currentBarrel: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientState obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.stock)
      ..writeByte(1)
      ..write(obj.currentBarrel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
