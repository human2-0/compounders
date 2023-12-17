import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';


part 'mixers_model.g.dart'; // The generated file for Hive adapter, ensure you create this

@HiveType(typeId: 2)
class Mixer {

  Mixer({
    required this.mixerId,
    required this.assignedProducts,
    required this.lastUpdated,
    required this.shift,
    required this.mixerName,
  });

  factory Mixer.fromJson(Map<String, dynamic> json) {
    final productsMap = <String, AssignedProduct>{};

    // Safely cast and handle potential null or missing values
    final assignedProductsMap = json['assignedProducts'] as Map<String, dynamic>?;
    if (assignedProductsMap != null) {
      assignedProductsMap.forEach((key, value) {
        productsMap[key] = AssignedProduct.fromJson(value as Map<String, dynamic>);
      });
    }

    return Mixer(
      mixerId: json['mixerId'] as String? ?? 'Unknown',
      assignedProducts: productsMap,
      lastUpdated: (json['lastUpdated'] is Timestamp) ? (json['lastUpdated'] as Timestamp).toDate() : DateTime.now(),
      shift: json['shift'] as String? ?? 'Default Shift',
      mixerName: json['mixerName'] as String? ?? 'Default name',
    );
  }
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


  Map<String, dynamic> toJson() {
    final productsMap = <String, dynamic>{};
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

  AssignedProduct({required this.productId, required this.amountToProduce});

  factory AssignedProduct.fromJson(Map<String, dynamic> json) => AssignedProduct(
      productId: json['productId'] as String,
      amountToProduce: json['amountToProduce'] as int,
    );
  final String productId;
  final int amountToProduce;

  Map<String, dynamic> toJson() => {
      'productId': productId,
      'amountToProduce': amountToProduce,
    };
}
