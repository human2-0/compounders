import 'package:hive/hive.dart';
part 'ingredient_model.g.dart';


@HiveType(typeId: 0)
class IngredientState {
  @HiveField(0)
  final double stock;
  @HiveField(1)
  final double currentBarrel;

  IngredientState({required this.stock, required this.currentBarrel});

  // Factory constructor to create an IngredientState from a Map
  factory IngredientState.fromMap(Map<String, dynamic> data) {
    return IngredientState(
      stock: data['stock'].toDouble(),
      currentBarrel: data['currentBarrel'].toDouble(),
    );
  }
}