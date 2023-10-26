import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';


part 'mixers_models.g.dart'; // The generated file for Hive adapter, ensure you create this

@HiveType(typeId: 2)
class Mixer {
  @HiveField(0)
  final String mixerId;

  @HiveField(1)
  final Map<String, AssignedProduct> assignedProducts;  // Using a Map now

  @HiveField(2)
  final DateTime lastUpdated;

  @HiveField(3)
  final String shift;


  @HiveField(5)
  final String mixerName;

  Mixer({
    required this.mixerId,
    required this.assignedProducts,
    required this.lastUpdated,
    required this.shift,
    required this.mixerName,
  });

  factory Mixer.fromJson(Map<String, dynamic> json) {
    Map<String, AssignedProduct> productsMap = {};

    // Safely cast and handle potential null or missing values
    Map<String, dynamic>? assignedProductsMap = json['assignedProducts'] as Map<String, dynamic>?;
    if (assignedProductsMap != null) {
      assignedProductsMap.forEach((key, value) {
        productsMap[key] = AssignedProduct.fromJson(value as Map<String, dynamic>);
      });
    }

    return Mixer(
      mixerId: json['mixerId'] ?? "Unknown",
      assignedProducts: productsMap,
      // Safely convert Timestamp to DateTime
      lastUpdated: (json['lastUpdated'] as Timestamp?)!.toDate(),
      shift: json['shift'],
      mixerName: json['mixerName'],
    );
  }


  Map<String, dynamic> toJson() {
    Map<String, dynamic> productsMap = {};
    assignedProducts.forEach((key, value) {
      productsMap[key] = value.toJson();
    });
    return {
      'mixerId': mixerId,
      'assignedProducts': productsMap,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'shift': shift,
      'mixerName': mixerName,
    };
  }
}

class AssignedProduct {
  final String productId;
  final int amountToProduce;

  AssignedProduct({required this.productId, required this.amountToProduce});

  factory AssignedProduct.fromJson(Map<String, dynamic> json) {
    return AssignedProduct(
      productId: json['productId'],
      amountToProduce: json['amountToProduce'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'amountToProduce': amountToProduce,
    };
  }
}




