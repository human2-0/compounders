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
      tareWeight: fields[2] as double,
      lastUpdated: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.stock)
      ..writeByte(1)
      ..write(obj.currentBarrel)
      ..writeByte(2)
      ..write(obj.tareWeight)
      ..writeByte(3)
      ..write(obj.lastUpdated);
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

class IngredientDataAdapter extends TypeAdapter<IngredientData> {
  @override
  final int typeId = 8;

  @override
  IngredientData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientData(
      ingredientPLU: fields[0] as String,
      ingredientState: fields[1] as IngredientState,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.ingredientPLU)
      ..writeByte(1)
      ..write(obj.ingredientState);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
