import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/utils.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

/// Manages interactions with Firestore for ingredient-related operations,
/// including updating ingredient data and logging ingredient usage.
class IngredientRepository {
  /// Constructor that initializes the repository with a Firestore instance.
  IngredientRepository(this._firestore);

  /// The Firestore instance used to perform database operations.
  final FirebaseFirestore _firestore;

  /// Updates ingredient data after a pouring action.
  /// This function should be called after an ingredient has been used (poured) during the compounding process.
  ///
  /// Parameters:
  ///   - `ingredientPLU`: The unique identifier for the ingredient.
  ///   - `usedAmount`: The amount of the ingredient that has been used.
  ///   - `requiredAmount`: The amount of the ingredient that was required.
  ///   - `difference`: The difference between the required amount and the used amount.
  Future<void> pourIngredient(String ingredientPLU, double usedAmount, double requiredAmount, double difference) async {
    double currentBarrelWeight;
    // Fetch data from Hive first to get the current state of the ingredient.
    final ingredientBox = await Hive.openBox<IngredientState>('ingredientBox');
    var ingredientData = ingredientBox.get(ingredientPLU);

    // Handle case where the ingredient data is not found in the local database.
    if (ingredientData == null) {
      throw Exception('No data found for the given PLU in Hive.');
    }

    // Calculate the new stock and barrel weight, taking into account the used amount and any difference.
    // Throws an exception if the new stock or barrel weight is less than 0, indicating insufficient stock.

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

    // Calculate monthly log key.
    ///TODO: please get rid of the 'getCurrentCycleDateRange' and fetch existing log with boolean flag 'inUse' earlier set by administrators.
    final cycle = getCurrentCycleDateRange(DateTime.now());
    final logKey =
        '${cycle.endDate.year}-${cycle.endDate.month.toString().padLeft(2, '0')}-${cycle.endDate.day.toString().padLeft(2, '0')}';
    // Run a Firestore transaction to ensure atomic updates to the ingredient data.
    return _firestore.runTransaction((transaction) async {
      // Firestore document references for the ingredient and its monthly logs.
      final DocumentReference ingredientRef = _firestore.collection('ingredients').doc(ingredientPLU);
      final DocumentReference monthlyLogRef = ingredientRef.collection('monthlyLogs').doc(logKey);

      // Check lastUpdated timestamp before fetching the entire document.
      // This is crucial to handle cases where the ingredient data might have been updated elsewhere (e.g., by another user or process).
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
        // Update the Firestore and Hive with the new stock and barrel weight.
        // Also update or create the monthly log with the used, overused, and wasted amounts.
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

  /// Handles the process when an entire barrel of an ingredient is used.
  ///
  /// Parameters:
  ///   - `usedAmount`: The amount of the ingredient that has been used from the barrel.
  ///   - `wastedAmount`: The amount of the ingredient wasted during the process.
  ///   - `ingredientPLU`: The unique identifier for the ingredient.
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
    final logKey =
        '${cycle.endDate.year}-${cycle.endDate.month.toString().padLeft(2, '0')}-${cycle.endDate.day.toString().padLeft(2, '0')}';

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

  /// Adjusts the weight of the current barrel based on the user input value.
  ///
  /// Parameters:
  ///   - `ingredientSnapshot`: The current state of the ingredient.
  ///   - `userValue`: The value input by the user, typically the measured weight.
  ///   - `ingredientPLU`: The unique identifier for the ingredient.
  ///   - `usedAmount`: The amount of the ingredient that has been used.
  ///   - `requiredAmount`: The required amount of the ingredient for the product.
  Future<void> adjustCurrentBarrelWeight(IngredientState ingredientSnapshot, double userValue, String ingredientPLU,
      double usedAmount, double requiredAmount) async {

    final currentBarrel = ingredientSnapshot.currentBarrel;
    final tareWeight = ingredientSnapshot.tareWeight;
    // Calculate the net weight and determine if there is a negative difference.
    // A negative difference would require adjusting the current barrel weight to reflect the actual weight.
    final netWeight = formatPrecision(userValue - tareWeight);
    var differenceBarrelCheck = formatPrecision(netWeight - (currentBarrel - usedAmount));

    // If difference is negative, adjust the current barrel
    if (differenceBarrelCheck < 0) {
      // Log the negative value

      await pourIngredient(ingredientPLU, usedAmount, requiredAmount, differenceBarrelCheck.abs());
    } else if (differenceBarrelCheck >= 0) {
      // We set the difference as 0 in case the barrel check declared more than it should be, thus we omit this value.
      // We can imply that the scales aren't calibrated accurately, however it's possible too, that user could add external resources to make up the results.
      differenceBarrelCheck = 0;

      await pourIngredient(ingredientPLU, usedAmount, requiredAmount, differenceBarrelCheck.abs());
    }
  }

  /// Logs the ingredient usage to Firestore, detailing the used, wasted, and overused amounts.
  ///
  /// Parameters:
  ///   - `log`: The [IngredientLog] object containing details of the ingredient usage.
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

  /// Top up the ingredient data with a new barrel and tare weight.
  ///
  /// Parameters:
  ///   - `currentBarrelWeight`: The weight of the current barrel before topping up.
  ///   - `newTareWeight`: The tare weight of the new barrel.
  ///   - `newBarrelWeight`: The total weight of the new barrel.
  ///   - `ingredientPLU`: The unique identifier for the ingredient.
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
          'wastedAmount': FieldValue.increment(formatPrecision(wastedAmount)),
        });
      } else {
        transaction.set(monthlyLogRef, {
          'startDate': cycle.startDate,
          'endDate': cycle.endDate,
          'wastedAmount': formatPrecision(wastedAmount),
        });
      }

      // Update ingredient data in Firestore and Hive
      transaction.update(ingredientRef, {
        'tareWeight': newTareWeight,
        'currentBarrel': newBarrelWeight,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      await ingredientBox.put(
          ingredientPLU,
          IngredientState.fromMap({
            'tareWeight': newTareWeight,
            'currentBarrel': newBarrelWeight,
            'lastUpdated': DateTime.now(),
          }));
    });
  }
}
