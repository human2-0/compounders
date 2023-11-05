import 'package:compounders/models/mixers_model.dart';
import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 4) // Ensure each HiveType has a unique typeId
class Product {
  Product({required this.productId, required this.amountToProduce});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        productId: json['productId'] as String,
        amountToProduce: json['amountToProduce'] as int,
      );
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final int amountToProduce;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'amountToProduce': amountToProduce,
      };
}

@HiveType(typeId: 5)
class ProductDetails {
  ProductDetails({
    required this.productName,
    required this.productFormula,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) => ProductDetails(
        productName: json['productName'] as String,
        productFormula: (json['productFormula'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                key,
                IngredientFormula.fromJson(value as Map<String, dynamic>),
              ),
            ) ??
            {},
      );

  @HiveField(0)
  final String productName;

  @HiveField(1)
  final Map<String, IngredientFormula> productFormula;

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'productFormula': productFormula.map((key, value) => MapEntry(key, value.toJson())),
      };
}

class ProductQueryData {
  ProductQueryData({
    required this.mixerName,
    required this.productId,
    required this.orderId,
  });
  final String mixerName;
  final String productId;
  final String orderId;
}

class ProductDisplayData {
  ProductDisplayData({
    required this.product,
    required this.productDetails,
    required this.queryData,
  });

  final AssignedProduct product; // Change type here
  final ProductDetails productDetails;
  final ProductQueryData queryData;
}

@HiveType(typeId: 6)
class IngredientFormula {
  IngredientFormula({
    required this.ingredientName,
    required this.percentage,
  });

  factory IngredientFormula.fromJson(Map<String, dynamic> json) => IngredientFormula(
        ingredientName: json['ingredientName'] as String,
        percentage: json['percentage'] as double,
      );

  @HiveField(0)
  final String ingredientName;

  @HiveField(1)
  final double percentage;

  Map<String, dynamic> toJson() => {
        'ingredientName': ingredientName,
        'percentage': percentage,
      };
}
