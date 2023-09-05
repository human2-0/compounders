
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/ingredient_model.dart';
import '../utils.dart';
import 'package:hive/hive.dart';

class IngredientRepository {
  final FirebaseFirestore _firestore;

  IngredientRepository(this._firestore);

  Future<void> pourIngredient(String ingredientPLU, double usedAmount,
      double requiredAmount, double difference) async {
    // Fetch data from Hive first.
    final ingredientBox = await Hive.openBox('ingredientBox');
    Map<String, dynamic> ingredientData = ingredientBox.get(ingredientPLU);


    DateTime lastSynced = ingredientData['lastUpdated'] ?? DateTime.fromMillisecondsSinceEpoch(0);


    double currentStock = ingredientData['stock'].toDouble();
    double newStock = formatPrecision(currentStock - usedAmount - difference);

    if (newStock < 0) {
      throw Exception(
          'Insufficient stock! Available: $currentStock, Requested: ${usedAmount + difference}');
    }

    double currentBarrelWeight = ingredientData['currentBarrel'];
    double newBarrelWeight = formatPrecision(currentBarrelWeight - usedAmount - difference);

    if (newBarrelWeight < 0) {
      throw Exception(
          'Current barrel insufficient! Available in barrel: $currentBarrelWeight, Requested: ${usedAmount - difference}');
    }

    double overUsedAmount = formatPrecision((usedAmount - requiredAmount).abs());

    // Calculate monthly log key
    CycleDateRange cycle = getCurrentCycleDateRange(DateTime.now());
    String logKey =
        '${cycle.endDate.year}-${cycle.endDate.month.toString().padLeft(2, '0')}-${cycle.endDate.day.toString().padLeft(2, '0')}';

    return _firestore.runTransaction((transaction) async {
      // References
      DocumentReference ingredientRef = _firestore.collection('ingredients').doc(ingredientPLU);
      DocumentReference monthlyLogRef = ingredientRef.collection('monthlyLogs').doc(logKey);

      // Check lastUpdated timestamp before fetching the entire document
      DocumentSnapshot timestampSnapshot = await transaction.get(ingredientRef);
      DateTime firestoreLastUpdated = timestampSnapshot.get('lastUpdated').toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);

      if (firestoreLastUpdated.isAfter(lastSynced)) {
        // Fetch the entire document if it has been updated since lastSynced
        ingredientData = (await transaction.get(ingredientRef)).data() as Map<String, dynamic>;
        lastSynced = firestoreLastUpdated;
        ingredientBox.put(ingredientPLU, {
          ...ingredientData,
          'lastUpdated': lastSynced,
        }); // Save the updated data to Hive

        // Recalculate values based on the fetched ingredientData
        currentStock = ingredientData['stock'];
        newStock = formatPrecision(currentStock - usedAmount - difference);

        currentBarrelWeight = ingredientData['currentBarrel'];
        newBarrelWeight = formatPrecision(currentBarrelWeight - usedAmount - difference);
      }

      DocumentSnapshot logSnapshot = await transaction.get(monthlyLogRef);

      // Update ingredient stock and barrel weight in Firestore and Hive
      transaction.update(ingredientRef, {
        'stock': newStock,
        'currentBarrel': newBarrelWeight,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
      ingredientBox.put(ingredientPLU, {
        ...ingredientData,
        'stock': newStock,
        'currentBarrel': newBarrelWeight,
        'lastUpdated': DateTime.now(),
      }); // Save the updated data to Hive

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


  Future<void> adjustCurrentBarrelWeight(
      IngredientState ingredientSnapshot, double userValue, String ingredientPLU, double usedAmount, double requiredAmount) async {
    double currentBarrel = ingredientSnapshot.currentBarrel;
    double tareWeight = ingredientSnapshot.tareWeight;

    double netWeight = formatPrecision(userValue - tareWeight);
    double differenceBarrelCheck = formatPrecision(netWeight - (currentBarrel - usedAmount));

    // If difference is negative, adjust the current barrel
    if (differenceBarrelCheck < 0) {
      double adjustedCurrentBarrel = formatPrecision(currentBarrel - requiredAmount + differenceBarrelCheck);

      // Log the negative value
      print('Negative value encountered: $differenceBarrelCheck, adjusting current barrel to $adjustedCurrentBarrel');

      // Since IngredientState is an immutable class, you can't update its properties directly like this:
      // ingredientSnapshot.currentBarrel = adjustedCurrentBarrel;
      // Instead, create a new instance or make adjustments accordingly.

      // Assuming you have a way to get the ingredientPLU from the IngredientState:
      // (You might need to adjust this if IngredientState doesn't have ingredientPLU)


      pourIngredient(ingredientPLU, usedAmount, requiredAmount, differenceBarrelCheck.abs());

    } else if ( differenceBarrelCheck >= 0) {
      // We set the difference as 0 in case the barrel check declared more than it should be, thus we omit this value.
      // We can imply that the scales aren't calibrated accurately, however it's possible too, that user could add external resources to make up the results.
      differenceBarrelCheck = 0;

      pourIngredient(ingredientPLU, usedAmount, requiredAmount, differenceBarrelCheck.abs());
    }


  }

  Future<void> productLogIngredients(IngredientLog log) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String docId = '${log.userId}_${log.productName}_$today';

    DocumentReference docRef =
        _firestore.collection('ingredientLog').doc(docId);

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
    double wastedAmount = currentBarrelWeight;

    // Calculate monthly log key
    CycleDateRange cycle = getCurrentCycleDateRange(DateTime.now());
    String logKey =
        '${cycle.endDate.year}-${cycle.endDate.month.toString().padLeft(2, '0')}-${cycle.endDate.day.toString().padLeft(2, '0')}';

    DocumentReference ingredientRef = _firestore.collection('ingredients').doc(ingredientPLU);
    DocumentReference monthlyLogRef = ingredientRef.collection('monthlyLogs').doc(logKey);
    final ingredientBox = await Hive.openBox('ingredientBox');

    return _firestore.runTransaction((transaction) async {
      // Fetch the monthly log
      DocumentSnapshot logSnapshot = await transaction.get(monthlyLogRef);

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

      ingredientBox.put(ingredientPLU, {
        'tareWeight': newTareWeight,
        'currentBarrel': newBarrelWeight,
        'lastUpdated': DateTime.now(),
      });
    });
  }


  Future<void> refreshData(String ingredientPLU) async {
    DocumentReference ingredientRef =
        FirebaseFirestore.instance.collection('ingredients').doc(ingredientPLU);
    final snapshot = await ingredientRef.get();

    final box = await Hive.openBox('ingredientBox');
    await box.put(ingredientPLU, snapshot.data() as Map<String, dynamic>);
  }
}

final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  return IngredientRepository(FirebaseFirestore.instance);
});



final ingredientBoxProvider = FutureProvider.autoDispose<Box>(
    (ref) async => await Hive.openBox('ingredientBox'));

final ingredientProvider = StreamProvider.autoDispose
    .family<IngredientState, String>((ref, ingredientPLU) async* {
  final box = await ref.watch(ingredientBoxProvider.future);

  if (box.containsKey(ingredientPLU)) {
    Map<String, dynamic>? cachedData =
    (box.get(ingredientPLU) as Map?)?.cast<String, dynamic>();
    if (cachedData != null) {
// Convert the cached data to IngredientState and return
      yield IngredientState.fromMap(cachedData);
    }
  }

  DocumentReference ingredientRef =
  FirebaseFirestore.instance.collection('ingredients').doc(ingredientPLU);

// Listen to the document's changes
  yield* ingredientRef.snapshots().asyncMap((snapshot) async {
    final data = snapshot.data();
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid data type from Firestore.');
    }
    data['lastUpdated'] = (data['lastUpdated'] as Timestamp).toDate();
    await box.put(ingredientPLU, data);
    return IngredientState.fromMap(data);
  });
    });



final isPouredProvider = StateProvider<bool>((ref) => false);
final selectedIngredientProvider = StateProvider<Ingredient?>((ref) {
  return null;
});

final pouredAmountBoxProvider = FutureProvider<Box>((ref) async {
  return await Hive.openBox('pouredAmountBox');
});


final usedAmountProvider = FutureProvider.family<Map<String, dynamic>, Ingredient>((ref, ingredient) async {
  final box = await Hive.openBox('pouredAmountBox');
  final data = box.get(ingredient.plu, defaultValue: {'date': '', 'usedAmount': 0.0});
  final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  if (data['date'] != currentDate) {
    box.put(ingredient.plu, {'date': currentDate, 'usedAmount': 0.0});
    return {'date': currentDate, 'usedAmount': 0.0};
  }

  return data.cast<String, dynamic>();
});

final amountStateProvider = StateNotifierProvider.family<AmountStateNotifier, AmountState, Ingredient>((ref, ingredient) {
  final requiredAmount = ingredient.percentage * ingredient.amountToProduce;
  return AmountStateNotifier(ref, ingredient, requiredAmount);
});

class AmountStateNotifier extends StateNotifier<AmountState> {
  final ref;
  final Ingredient ingredient;
  final double requiredAmount;

  AmountStateNotifier(this.ref, this.ingredient, this.requiredAmount) : super(AmountState(requiredAmount, 0)) {
    _loadInitialUsedAmount();
  }

  Future<void> _loadInitialUsedAmount() async {
    final data = await ref.read(usedAmountProvider(ingredient).future);
    state = AmountState(requiredAmount, formatPrecision(data['usedAmount']));
  }

  void updateUsedAmount(double newUsedAmount) {
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final box = Hive.box('pouredAmountBox');
    final updatedUsedAmount = state.usedAmount + newUsedAmount;
    box.put(ingredient.plu, {'date': currentDate, 'usedAmount': formatPrecision(updatedUsedAmount)});
    state = AmountState(requiredAmount, updatedUsedAmount);
  }
}


