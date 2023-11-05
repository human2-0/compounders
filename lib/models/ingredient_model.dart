import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'ingredient_model.g.dart';

@HiveType(typeId: 0)
class IngredientState {
  IngredientState(
      {required this.stock, required this.currentBarrel, required this.tareWeight, required this.lastUpdated});

  // Factory constructor to create an IngredientState from a Map
  factory IngredientState.fromMap(Map<String, dynamic> data) => IngredientState(
      stock: (data['stock'] as num?)?.toDouble() ?? 0.0,
      currentBarrel: (data['currentBarrel'] as num?)?.toDouble() ?? 0.0,
      tareWeight: (data['tareWeight'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: data['lastUpdated'] as DateTime? ?? DateTime.now());

  @HiveField(0)
  late final double stock;

  @HiveField(1)
  final double currentBarrel;

  @HiveField(2)
  final double tareWeight;

  @HiveField(3)
  late final DateTime lastUpdated;

  Map<String, dynamic> toMap() => {
        'stock': stock,
        'currentBarrel': currentBarrel,
        'tareWeight': tareWeight,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      };
}

class Ingredient {
  Ingredient(
      {required this.name,
      required this.percentage,
      required this.plu,
      required this.amountToProduce,
      required this.productName});

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        plu: json['plu'] as String? ?? '',
        name: json['name'] as String? ?? '',
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
        amountToProduce: json['amountToProduce'] as int? ?? 0,
        productName: json['productId'] as String? ?? '',
      );
  final String plu;
  final String name;
  final double percentage;
  final int amountToProduce;
  final String productName;
}

class IngredientLog {
  IngredientLog({
    required this.userId,
    required this.productName,
    required this.ingredientId,
    required this.ingredientName,
    required this.usedAmount,
    required this.wastedAmount,
    required this.overUsedAmount,
  }) : timestamp = Timestamp.now();
  final String userId;
  final String productName;
  final String ingredientId;
  final String ingredientName;
  final double usedAmount;
  final double wastedAmount;
  final double overUsedAmount;
  final Timestamp timestamp;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'productName': productName,
        'ingredientId': ingredientId,
        'ingredientName': ingredientName,
        'usedAmount': usedAmount,
        'wastedAmount': wastedAmount,
        'overUsedAmount': overUsedAmount,
        'timestamp': timestamp,
      };
}

@HiveType(typeId: 8)
class IngredientData {
  IngredientData({required this.ingredientPLU, required this.ingredientState});

  factory IngredientData.fromMap(Map<String, dynamic> map) => IngredientData(
        ingredientPLU: map['ingredientPLU'] as String,
        ingredientState: IngredientState.fromMap(map['ingredientState'] as Map<String, dynamic>),
      );

  @HiveField(0)
  final String ingredientPLU;

  @HiveField(1)
  final IngredientState ingredientState;

  Map<String, dynamic> toMap() => {
        'ingredientPLU': ingredientPLU,
        'ingredientState': ingredientState.toMap(),
      };
}
