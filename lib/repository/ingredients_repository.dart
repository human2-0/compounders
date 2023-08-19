import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/ingredient_model.dart';
import '../models/mixers_models.dart';
import '../utils.dart';
import 'package:hive/hive.dart';

class IngredientRepository {
  final FirebaseFirestore _firestore;

  IngredientRepository(this._firestore);
  Future<void> pourIngredient(String ingredientPLU, double amountToDeduct, double requiredAmount) async {
    // Fetch data from Hive first.
    final ingredientBox = await Hive.openBox('ingredientBox');
    final ingredientData = ingredientBox.get(ingredientPLU);

    if (ingredientData == null) {
      throw Exception('Ingredient not found!');
    }

    double currentStock = ingredientData['stock'].toDouble();
    double newStock = currentStock - amountToDeduct;

    if (newStock < 0) {
      throw Exception('Insufficient stock! Available: $currentStock, Requested: $amountToDeduct');
    }

    double currentBarrelWeight = ingredientData['currentBarrel'].toDouble();
    double newBarrelWeight = currentBarrelWeight - amountToDeduct;

    if (newBarrelWeight < 0) {
      throw Exception('Current barrel insufficient! Available in barrel: $currentBarrelWeight, Requested: $amountToDeduct');
    }

    double amountWasted = max(0.0, amountToDeduct - requiredAmount);

    // Calculate monthly log key
    CycleDateRange cycle = getCurrentCycleDateRange(DateTime.now());
    String logKey = '${cycle.endDate.year}-${cycle.endDate.month.toString().padLeft(2, '0')}-${cycle.endDate.day.toString().padLeft(2, '0')}';

    return _firestore.runTransaction((transaction) async {
      // References
      DocumentReference ingredientRef = _firestore.collection('ingredients').doc(ingredientPLU);
      DocumentReference monthlyLogRef = ingredientRef.collection('monthlyLogs').doc(logKey);

      DocumentSnapshot logSnapshot = await transaction.get(monthlyLogRef);

      // Update ingredient stock and barrel weight in Firestore and Hive
      transaction.update(ingredientRef, {
        'stock': newStock,
        'currentBarrel': newBarrelWeight
      });

      ingredientBox.put(ingredientPLU, {
        'stock': newStock,
        'currentBarrel': newBarrelWeight
      });

      // Update or set the monthly log in Firestore
      if (logSnapshot.exists) {
        transaction.update(monthlyLogRef, {
          'totalUsed': FieldValue.increment(amountToDeduct),
          'amountWasted': FieldValue.increment(amountWasted),
        });
      } else {
        transaction.set(monthlyLogRef, {
          'startDate': cycle.startDate,
          'endDate': cycle.endDate,
          'totalUsed': amountToDeduct,
          'amountWasted': amountWasted,
        });
      }
    });
  }


  Future<void> productLogIngredients(IngredientLog log) async {

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String docId = '${log.userId}_${log.productName}_$today';

    DocumentReference docRef = _firestore.collection('ingredientLog').doc(docId);

    // Directly set the data with merge option
    await docRef.set({
      'userId': log.userId,
      'productName': log.productName,
      'logDate': today,
      'ingredients': {
        '${log.ingredientId}:${log.ingredientName}': {
          'usedAmount': FieldValue.increment(log.usedAmount),
          'wastedAmount': FieldValue.increment(log.wastedAmount)
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> refreshData(String ingredientPLU) async {
    DocumentReference ingredientRef = FirebaseFirestore.instance.collection('ingredients').doc(ingredientPLU);
    final snapshot = await ingredientRef.get();

    final box = await Hive.openBox('ingredientBox');
    await box.put(ingredientPLU, snapshot.data());
  }
}


final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  return IngredientRepository(FirebaseFirestore.instance);
});

// final ingredientProvider = FutureProvider.autoDispose.family<DocumentSnapshot, String>((ref, ingredientPLU) async {
//   DocumentReference ingredientRef = FirebaseFirestore.instance.collection('ingredients').doc(ingredientPLU);
//   return await ingredientRef.get();
// });

final ingredientBoxProvider = FutureProvider.autoDispose<Box>((ref) async => await Hive.openBox('ingredientBox'));

final ingredientProvider = FutureProvider.autoDispose.family<IngredientState, String>(
        (ref, ingredientPLU) async {
      final box = await ref.watch(ingredientBoxProvider.future);

      if (box.containsKey(ingredientPLU)) {
        Map<String, dynamic>? cachedData = box.get(ingredientPLU);
        if (cachedData != null) {
          // Convert the cached data to IngredientState and return
          return IngredientState.fromMap(cachedData);
        }
      }

      DocumentReference ingredientRef = FirebaseFirestore.instance.collection('ingredients').doc(ingredientPLU);
      final snapshot = await ingredientRef.get();

      await box.put(ingredientPLU, snapshot.data());

      // Convert the snapshot data to IngredientState and return
      return IngredientState.fromMap(snapshot.data() as Map<String,dynamic>);
    }
);