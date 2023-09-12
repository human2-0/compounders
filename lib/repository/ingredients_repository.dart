
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

import '../models/ingredient_model.dart';
import '../utils.dart';
import 'package:hive/hive.dart';

class IngredientRepository {
  final FirebaseFirestore _firestore;

  IngredientRepository(this._firestore);

  Future<void> pourIngredient(String ingredientPLU, double usedAmount,
      double requiredAmount, double difference) async {
    double currentBarrelWeight;
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

    if (ingredientData['currentBarrel'] is String) {
      currentBarrelWeight = double.tryParse(ingredientData['currentBarrel'])!;
    } else if (ingredientData['currentBarrel'] is double) {
      currentBarrelWeight = ingredientData['currentBarrel'];
    } else {
      // Handle the case when it's neither a double nor a string, maybe set a default value or throw an error.
      currentBarrelWeight = 0.0; // or some default value
    }
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

  Future<void> pourWholeBarrel(double usedAmount, double wastedAmount, String ingredientPLU) async {
    // Fetch data from Hive first.
    final ingredientBox = await Hive.openBox('ingredientBox');
    Map<String, dynamic> ingredientData = ingredientBox.get(ingredientPLU);


    DateTime lastSynced = ingredientData['lastUpdated'] ?? DateTime.fromMillisecondsSinceEpoch(0);


    double currentStock = ingredientData['stock'].toDouble();
    double newStock = formatPrecision(currentStock - usedAmount);

    if (newStock < 0) {
      throw Exception(
          'Insufficient stock! Available: $currentStock, Requested: $usedAmount');
    }

    double currentBarrelWeight = ingredientData['currentBarrel'];
    double newBarrelWeight = formatPrecision(currentBarrelWeight - usedAmount);

    if (newBarrelWeight < 0) {
      throw Exception(
          'Current barrel insufficient! Available in barrel: $currentBarrelWeight, Requested: $usedAmount');
    }


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
        newStock = formatPrecision(currentStock - usedAmount);

        currentBarrelWeight = ingredientData['currentBarrel'];
        newBarrelWeight = formatPrecision(currentBarrelWeight - usedAmount);
      }

      DocumentSnapshot logSnapshot = await transaction.get(monthlyLogRef);

      // Update ingredient stock and barrel weight in Firestore and Hive
      transaction.update(ingredientRef, {
        'stock': newStock,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
      ingredientBox.put(ingredientPLU, {
        ...ingredientData,
        'stock': newStock,
        'lastUpdated': DateTime.now(),
      }); // Save the updated data to Hive

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


final usedAmountProvider = FutureProvider.family<Map<String, dynamic>, Tuple2<String, Ingredient>>((ref, tuple) async {
  final orderId = tuple.item1;
  final ingredient = tuple.item2;

  final boxKey = "$orderId-${ingredient.plu}";

  final box = await Hive.openBox('pouredAmountBox');
  final data = box.get(boxKey, defaultValue: {'date': '', 'usedAmount': 0.0});
  final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  if (data['date'] != currentDate) {
    box.put(boxKey, {'date': currentDate, 'usedAmount': 0.0});
    return {'date': currentDate, 'usedAmount': 0.0};
  }

  return data.cast<String, dynamic>();
});


final amountStateProvider = StateNotifierProvider.family<AmountStateNotifier, AmountState, Tuple2<String, Ingredient>>((ref, tuple) {
  final orderId = tuple.item1;
  final ingredient = tuple.item2;
  final requiredAmount = ingredient.percentage * ingredient.amountToProduce;
  return AmountStateNotifier(ref, orderId, ingredient, requiredAmount);
});


class AmountStateNotifier extends StateNotifier<AmountState> {
  final ref;
  final Ingredient ingredient;
  final double requiredAmount;
  final String orderId;

  AmountStateNotifier(this.ref, this.orderId, this.ingredient, this.requiredAmount)
      : super(AmountState(requiredAmount, 0)) {
    _loadInitialUsedAmount();
  }

  Future<void> _loadInitialUsedAmount() async {
    final data = await ref.read(usedAmountProvider(Tuple2(orderId,ingredient)).future);
    print(' here is init used amount$data');
    state = AmountState(requiredAmount, formatPrecision(data['usedAmount']));
  }

  void updateUsedAmount(double newUsedAmount) {
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final boxKey = "$orderId-${ingredient.plu}";
    final box = Hive.box('pouredAmountBox');
    final updatedUsedAmount = state.usedAmount + newUsedAmount;
    box.put(boxKey, {'date': currentDate, 'usedAmount': formatPrecision(updatedUsedAmount)});
    state = AmountState(requiredAmount, updatedUsedAmount);
  }
}


final allIngredientsMeetConditionProvider = FutureProvider.family<bool, Tuple2<String, List<Ingredient>>>((ref, tuple) async {
  print('Executing allIngredientsMeetConditionProvider for orderId: ${tuple.item1}');

  String orderId = tuple.item1;
  List<Ingredient> ingredients = tuple.item2;

  // Open the Hive box
  final box = await ref.read(pouredAmountBoxProvider.future);

  print('Started allIngredientsMeetConditionProvider for orderId: $orderId');

  for (final ingredient in ingredients) {
    final boxKey = "$orderId-${ingredient.plu}";

    // Get the usedAmount for the ingredient from the Hive box
    // Note: Here I'm assuming the data stored in Hive is just the used amount as a double, based on your previous example.
    // If it's a map or another data structure, you'll need to adjust this.
    final usedAmount = box.get(boxKey, defaultValue: 0.0);
    print('full box document: $usedAmount');

    print('Checking ingredient: ${ingredient.name} with usedAmount: ${usedAmount['usedAmount']} and requiredAmount: ${ingredient.amountToProduce * ingredient.percentage}'); // Adjust the requiredAmount if necessary

    if (usedAmount['usedAmount'] < (0.998 * ingredient.amountToProduce * ingredient.percentage)) { // Adjust the requiredAmount if necessary
      print('Ingredient: ${ingredient.name} does not meet condition.');
      return false;
    }
    print('this ingredient passed the true test');
  }

  print('All ingredients meet condition for orderId: $orderId');
  return true;
});

