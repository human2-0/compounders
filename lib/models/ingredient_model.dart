import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'ingredient_model.g.dart';


@HiveType(typeId: 0)
class IngredientState {
  @HiveField(0)
  final double stock;
  @HiveField(1)
  final double currentBarrel;
  @HiveField(2)
  final double tareWeight;
  @HiveField(3)
  final DateTime lastUpdated;

  IngredientState({required this.stock, required this.currentBarrel, required this.tareWeight, required this.lastUpdated});

  // Factory constructor to create an IngredientState from a Map
  factory IngredientState.fromMap(Map<String, dynamic> data) {
    return IngredientState(
      stock: data['stock'].toDouble(),
      currentBarrel: data['currentBarrel'].toDouble(),
      tareWeight: data['tareWeight'].toDouble(),
      lastUpdated: data['lastUpdated'],
    );
  }
}

class Ingredient {
  final String plu;
  final String name;
  final double percentage;
  final int amountToProduce;
  final String productName;

  Ingredient({required this.name, required this.percentage, required this.plu, required this.amountToProduce, required this.productName});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      plu: json['plu'],
      name: json['name'],
      percentage: (json['percentage'] as num).toDouble(),
      amountToProduce: json['amountToProduce'] as int,
      productName: json['productId'],
    );
  }
}

class IngredientLog {
  final String userId;
  final String productName;
  final String ingredientId;
  final String ingredientName;
  final double usedAmount;
  final double wastedAmount;
  final double overUsedAmount;
  final Timestamp timestamp;

  IngredientLog({
    required this.userId,
    required this.productName,
    required this.ingredientId,
    required this.ingredientName,
    required this.usedAmount,
    required this.wastedAmount,
    required this.overUsedAmount,
  }): timestamp = Timestamp.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productName': productName,
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'usedAmount': usedAmount,
      'wastedAmount': wastedAmount,
      'overUsedAmount' : overUsedAmount,
      'timestamp': timestamp,
    };
  }
}

class AmountState {
  final double requiredAmount;
  final double usedAmount;

  AmountState(this.requiredAmount, this.usedAmount);
}

