import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 4) // Ensure each HiveType has a unique typeId
class Product {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final int amountToProduce;

  Product({required this.productId, required this.amountToProduce});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] as String,
      amountToProduce: json['amountToProduce'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'amountToProduce': amountToProduce,
    };
  }
}




@HiveType(typeId: 5) // Ensure each HiveType has a unique typeId
class ProductDetails {
  @HiveField(0)
  final String productName;

  @HiveField(1)
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

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'productFormula': productFormula,
    };
  }
}