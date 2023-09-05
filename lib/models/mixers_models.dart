import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/product_model.dart';
import 'package:hive/hive.dart';


part 'mixers_models.g.dart'; // The generated file for Hive adapter, ensure you create this

@HiveType(typeId: 2)
class Mixer {
  @HiveField(0)
  final String mixerId;

  @HiveField(1)
  final List<Product> assignedProducts;

  @HiveField(2)
  final DateTime lastUpdated;

  @HiveField(3)
  final String shift;

  @HiveField(4)
  final int capacity;

  @HiveField(5)
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

  Map<String, dynamic> toJson() {
    return {
      'mixerId': mixerId,
      'assignedProducts': assignedProducts.map((product) => product.toJson()).toList(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'shift': shift,
      'capacity': capacity,
      'mixerName': mixerName,
    };
  }
}






