import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class Mixer {
  final String mixerId;
  final List<Product> assignedProducts;
  // assuming you want to capture the additional fields
  final DateTime lastUpdated;
  final String shift;
  final int capacity;
  final String mixerName;

  Mixer({
    required this.mixerId,
    required this.assignedProducts,
    required this.lastUpdated,
    required this.shift,
    required this.capacity,
    required this.mixerName,
  });

  factory Mixer.fromJson(Map<String, dynamic> json) {
    return Mixer(
      mixerId: json['mixerName'] ?? "Unknown", // use mixerName as the mixerId
      assignedProducts: [
        Product.fromJson(json['assignedProducts'] as Map<String, dynamic>)
      ], // Wrapping in a list since assignedProducts seems to be a Map
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
      shift: json['shift'],
      capacity: json['capacity'],
      mixerName: json['mixerName'],
    );
  }
}

class Product {
  final String productId;
  final int amountToProduce;

  Product({required this.productId, required this.amountToProduce});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
        productId: json['productId'], amountToProduce: json['amountToProduce']);
  }
}

class ProductDetails {
  final String productName;
  final Map<String, dynamic> productFormula;

  ProductDetails({
    required this.productName,
    required this.productFormula,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      productName: json['productName'],
      productFormula: json['productFormula'] as Map<String, dynamic>,
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
  final Timestamp timestamp;

  IngredientLog({
    required this.userId,
    required this.productName,
    required this.ingredientId,
    required this.ingredientName,
    required this.usedAmount,
    required double requiredAmount,
    required double userValue,
  })  : wastedAmount = (requiredAmount - userValue < 0)
      ? double.parse((requiredAmount - userValue).toStringAsFixed(3)).abs()
      : 0.0,
        timestamp = Timestamp.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productName': productName,
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'usedAmount': usedAmount,
      'wastedAmount': wastedAmount,
      'timestamp': timestamp,
    };
  }
}

