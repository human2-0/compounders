import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/models/product_model.dart';
import 'package:compounders/providers/products_provider.dart';
import 'package:compounders/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class IngredientRepository {
  IngredientRepository(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> pourIngredient(String ingredientPLU, double usedAmount, double requiredAmount, double difference) async {
    double currentBarrelWeight;
    // Fetch data from Hive first.
    final ingredientBox = await Hive.openBox<IngredientState>('ingredientBox');
    var ingredientData = ingredientBox.get(ingredientPLU);

    if (ingredientData == null) {
      throw Exception('No data found for the given PLU in Hive.');
    }

    var lastSynced = ingredientData.lastUpdated;

    var currentStock = ingredientData.stock;
    var newStock = formatPrecision(currentStock - usedAmount - difference);

    if (newStock < 0) {
      throw Exception('Insufficient stock! Available: $currentStock, Requested: ${usedAmount + difference}');
    }

      currentBarrelWeight = ingredientData.currentBarrel;
    var newBarrelWeight = formatPrecision(currentBarrelWeight - usedAmount - difference);

    if (newBarrelWeight < 0) {
      throw Exception(
          'Current barrel insufficient! Available in barrel: $currentBarrelWeight, Requested: ${usedAmount - difference}');
    }

    final overUsedAmount = formatPrecision((usedAmount - requiredAmount).abs());

    // Calculate monthly log key
    final cycle = getCurrentCycleDateRange(DateTime.now());
    final logKey =
        '${cycle.endDate.year}-${cycle.endDate.month.toString().padLeft(2, '0')}-${cycle.endDate.day.toString().padLeft(2, '0')}';

    return _firestore.runTransaction((transaction) async {
      // References
      final DocumentReference ingredientRef = _firestore.collection('ingredients').doc(ingredientPLU);
      final DocumentReference monthlyLogRef = ingredientRef.collection('monthlyLogs').doc(logKey);

      // Check lastUpdated timestamp before fetching the entire document
      final timestampSnapshot = await transaction.get(ingredientRef);
      final timestamp = timestampSnapshot.get('lastUpdated') as Timestamp?;
      final firestoreLastUpdated = timestamp?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);


      if (firestoreLastUpdated.isAfter(lastSynced)) {
        // Fetch the entire document if it has been updated since lastSynced
        final dataMap = (await transaction.get(ingredientRef)).data()! as Map<String, dynamic>;
        ingredientData = IngredientState.fromMap(dataMap);
        lastSynced = firestoreLastUpdated;

        // Create a new IngredientState object with updated 'lastUpdated' and convert it to a map
        final updatedIngredientState = IngredientState(
          stock: ingredientData!.stock,
          currentBarrel: ingredientData!.currentBarrel,
          tareWeight: ingredientData!.tareWeight,
          lastUpdated: lastSynced,
        );

        await ingredientBox.put(ingredientPLU, updatedIngredientState); // Save the updated data to Hive

        // Recalculate values based on the fetched ingredientData
        currentStock = ingredientData!.stock;
        newStock = formatPrecision(currentStock - usedAmount - difference);

        currentBarrelWeight = ingredientData!.currentBarrel;
        newBarrelWeight = formatPrecision(currentBarrelWeight - usedAmount - difference);
      }


      final logSnapshot = await transaction.get(monthlyLogRef);

      // Update ingredient stock and barrel weight in Firestore and Hive
      transaction.update(ingredientRef, {
        'stock': newStock,
        'currentBarrel': newBarrelWeight,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      final updatedIngredientState = IngredientState(
        stock: ingredientData!.stock,
        currentBarrel: ingredientData!.currentBarrel,
        tareWeight: ingredientData!.tareWeight,
        lastUpdated: lastSynced,
      );

      await ingredientBox.put(ingredientPLU, updatedIngredientState); // Save the updated data to Hive

      // Update or set the monthly log in Firestore
      if (logSnapshot.exists) {
        transaction.update(monthlyLogRef, {
          'totalUsed': FieldValue.increment(formatPrecision(usedAmount)),
          'overusedAmount': FieldValue.increment(formatPrecision(overUsedAmount)),
          'wastedAmount': FieldValue.increment(formatPrecision(difference)),
        });
      } else {
        transaction.set(monthlyLogRef, {
          'startDate': cycle.startDate,
          'endDate': cycle.endDate,
          'TotalUsed': formatPrecision(usedAmount),
          'overusedAmount': formatPrecision(overUsedAmount),
          'wastedAmount': formatPrecision(difference),
        });
      }
    });
  }

  Future<void> pourWholeBarrel(double usedAmount, double wastedAmount, String ingredientPLU) async {
    // Fetch data from Hive first.
    final ingredientBox = await Hive.openBox<IngredientState>('ingredientBox');
    var ingredientData = ingredientBox.get(ingredientPLU);

    if (ingredientData == null) {
      throw Exception('No data found for the given PLU in Hive.');
    }

    var lastSynced = ingredientData.lastUpdated;

    var currentStock = ingredientData.stock;
    var newStock = formatPrecision(currentStock - usedAmount);

    if (newStock < 0) {
      throw Exception('Insufficient stock! Available: $currentStock, Requested: $usedAmount');
    }

    var currentBarrelWeight = ingredientData.currentBarrel;
    var newBarrelWeight = formatPrecision(currentBarrelWeight - usedAmount);

    if (newBarrelWeight < 0) {
      throw Exception('Current barrel insufficient! Available in barrel: $currentBarrelWeight, Requested: $usedAmount');
    }

    // Calculate monthly log key
    final cycle = getCurrentCycleDateRange(DateTime.now());
    final logKey = '${cycle.endDate.year}-${cycle.endDate.month.toString().padLeft(2, '0')}-${cycle.endDate.day.toString().padLeft(2, '0')}';

    return _firestore.runTransaction((transaction) async {
      // References
      final DocumentReference ingredientRef = _firestore.collection('ingredients').doc(ingredientPLU);
      final DocumentReference monthlyLogRef = ingredientRef.collection('monthlyLogs').doc(logKey);

      // Check lastUpdated timestamp before fetching the entire document
      final timestampSnapshot = await transaction.get(ingredientRef);
      final firestoreLastUpdated = (timestampSnapshot.get('lastUpdated') as Timestamp).toDate();

      if (firestoreLastUpdated.isAfter(lastSynced)) {
        // Fetch the entire document if it has been updated since lastSynced
        final dataMap = (await transaction.get(ingredientRef)).data()! as Map<String, dynamic>;
        ingredientData = IngredientState.fromMap(dataMap);
        lastSynced = firestoreLastUpdated;

        await ingredientBox.put(ingredientPLU, ingredientData!); // Save the updated data to Hive

        // Recalculate values based on the fetched ingredientData
        currentStock = ingredientData!.stock;
        newStock = formatPrecision(currentStock - usedAmount);

        currentBarrelWeight = ingredientData!.currentBarrel;
        newBarrelWeight = formatPrecision(currentBarrelWeight - usedAmount);
      }

      final logSnapshot = await transaction.get(monthlyLogRef);

      // Update ingredient stock and barrel weight in Firestore and Hive
      transaction.update(ingredientRef, {
        'stock': newStock,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      ingredientData!.stock = newStock;
      ingredientData!.lastUpdated = DateTime.now();

      await ingredientBox.put(ingredientPLU, ingredientData!); // Save the updated data to Hive

      // Update or set the monthly log in Firestore
      if (logSnapshot.exists) {
        transaction.update(monthlyLogRef, {
          'totalUsed': FieldValue.increment(formatPrecision(usedAmount)),
          'wastedAmount': FieldValue.increment(formatPrecision(wastedAmount)),
        });
      } else {
        transaction.set(monthlyLogRef, {
          'startDate': cycle.startDate,
          'endDate': cycle.endDate,
          'TotalUsed': formatPrecision(usedAmount),
          'wastedAmount': formatPrecision(wastedAmount),
        });
      }
    });
  }


  Future<void> adjustCurrentBarrelWeight(IngredientState ingredientSnapshot, double userValue, String ingredientPLU,
      double usedAmount, double requiredAmount) async {
    final currentBarrel = ingredientSnapshot.currentBarrel;
    final tareWeight = ingredientSnapshot.tareWeight;

    final netWeight = formatPrecision(userValue - tareWeight);
    var differenceBarrelCheck = formatPrecision(netWeight - (currentBarrel - usedAmount));

    // If difference is negative, adjust the current barrel
    if (differenceBarrelCheck < 0) {
      // Log the negative value

      // Since IngredientState is an immutable class, you can't update its properties directly like this:
      // ingredientSnapshot.currentBarrel = adjustedCurrentBarrel;
      // Instead, create a new instance or make adjustments accordingly.

      // Assuming you have a way to get the ingredientPLU from the IngredientState:
      // (You might need to adjust this if IngredientState doesn't have ingredientPLU)

      await pourIngredient(ingredientPLU, usedAmount, requiredAmount, differenceBarrelCheck.abs());
    } else if (differenceBarrelCheck >= 0) {
      // We set the difference as 0 in case the barrel check declared more than it should be, thus we omit this value.
      // We can imply that the scales aren't calibrated accurately, however it's possible too, that user could add external resources to make up the results.
      differenceBarrelCheck = 0;

      await pourIngredient(ingredientPLU, usedAmount, requiredAmount, differenceBarrelCheck.abs());
    }
  }

  Future<void> productLogIngredients(IngredientLog log) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${log.userId}_${log.productName}_$today';

    final DocumentReference docRef = _firestore.collection('ingredientLog').doc(docId);

    // Directly set the data with merge option
    await docRef.set({
      'userId': log.userId,
      'productName': log.productName,
      'logDate': today,
      'ingredients': {
        '${log.ingredientId}:${log.ingredientName}': {
          'usedAmount': FieldValue.increment(formatPrecision(log.usedAmount)),
          'wastedAmount': FieldValue.increment(formatPrecision(log.wastedAmount)),
          'overUsedAmount': FieldValue.increment(formatPrecision(log.overUsedAmount))
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> topUpIngredient({
    required double currentBarrelWeight,
    required double newTareWeight,
    required double newBarrelWeight,
    required String ingredientPLU,
  }) async {
    // Check the amount left in the currentBarrel and increment the monthlyLog wastedAmount by currentBarrelWeight
    final wastedAmount = currentBarrelWeight;

    // Calculate monthly log key
    final cycle = getCurrentCycleDateRange(DateTime.now());
    final logKey =
        '${cycle.endDate.year}-${cycle.endDate.month.toString().padLeft(2, '0')}-${cycle.endDate.day.toString().padLeft(2, '0')}';

    final DocumentReference ingredientRef = _firestore.collection('ingredients').doc(ingredientPLU);
    final DocumentReference monthlyLogRef = ingredientRef.collection('monthlyLogs').doc(logKey);
    final ingredientBox = await Hive.openBox<IngredientState>('ingredientBox');

    return _firestore.runTransaction((transaction) async {
      // Fetch the monthly log
      final logSnapshot = await transaction.get(monthlyLogRef);

      // Update or set the monthly log in Firestore for wastedAmount
      if (logSnapshot.exists) {
        transaction.update(monthlyLogRef, {
          'wastedAmount': FieldValue.increment(wastedAmount),
        });
      } else {
        transaction.set(monthlyLogRef, {
          'startDate': cycle.startDate,
          'endDate': cycle.endDate,
          'wastedAmount': wastedAmount,
        });
      }

      // Update ingredient data in Firestore and Hive
      transaction.update(ingredientRef, {
        'tareWeight': newTareWeight,
        'currentBarrel': newBarrelWeight,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      await ingredientBox.put(ingredientPLU, IngredientState.fromMap({
        'tareWeight': newTareWeight,
        'currentBarrel': newBarrelWeight,
        'lastUpdated': DateTime.now(),
      }));
    });
  }

  Future<void> refreshData(String ingredientPLU) async {
    final DocumentReference ingredientRef = FirebaseFirestore.instance.collection('ingredients').doc(ingredientPLU);
    final snapshot = await ingredientRef.get();

    final box = await Hive.openBox<IngredientState>('ingredientBox');
    await box.put(ingredientPLU, snapshot.data()! as IngredientState);
  }
}

final ingredientRepositoryProvider =
    Provider<IngredientRepository>((ref) => IngredientRepository(FirebaseFirestore.instance));

final ingredientBoxProvider = FutureProvider.autoDispose<Box<IngredientState>>((ref) async => Hive.openBox<IngredientState>('ingredientBox'));

final ingredientProvider = StreamProvider.autoDispose.family<IngredientState, String>((ref, ingredientPLU) async* {
  final box = await ref.watch(ingredientBoxProvider.future);

  if (box.containsKey(ingredientPLU)) {
    final cachedData = box.get(ingredientPLU);
    if (cachedData != null) {
      // Return the cached data as it's already an IngredientState
      yield cachedData;
    }
  }

  final DocumentReference ingredientRef = FirebaseFirestore.instance.collection('ingredients').doc(ingredientPLU);

  // Listen to the document's changes
  yield* ingredientRef.snapshots().asyncMap((snapshot) async {
    final data = snapshot.data();
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid data type from Firestore.');
    }
    data['lastUpdated'] = (data['lastUpdated'] as Timestamp).toDate();
    final ingredientState = IngredientState.fromMap(data);
    await box.put(ingredientPLU, ingredientState); // Store IngredientState in the box
    return ingredientState;
  });
});

final ingredientsByProductNameProvider = Provider.family<List<Ingredient>, String>((ref, productName) {
  final productListAsyncValue = ref.watch(consolidatedProductListProvider);

  // If the productListAsyncValue is still loading or has an error, return an empty list
  if (productListAsyncValue is! AsyncData<List<ProductDisplayData>>) {
    return [];
  }

  final productList = productListAsyncValue.value ?? [];

  // Search for the product matching the productName
  for (final productDisplayData in productList) {
    if (productDisplayData.productDetails.productName == productName) {
      return productDisplayData.productDetails.productFormula.entries.map((entry) {
        final plu = entry.key;
        final ingredientData = entry.value;
        return Ingredient(
          plu: plu,
          name: ingredientData.ingredientName,
          percentage: ingredientData.percentage,
          amountToProduce: productDisplayData.product.amountToProduce,
          productName: productDisplayData.productDetails.productName,
        );
      }).toList();
    }
  }

  // Return an empty list if no matching product is found
  return [];
});
