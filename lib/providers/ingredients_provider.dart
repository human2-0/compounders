import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/models/product_model.dart';
import 'package:compounders/models/used_amount_model.dart';
import 'package:compounders/providers/products_provider.dart';
import 'package:compounders/repository/ingredients_repository.dart';
import 'package:compounders/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

final isPouredProvider = StateProvider<bool>((ref) => false);
final selectedIngredientProvider = StateProvider<Ingredient?>((ref)=>null);

final usedAmountProvider = FutureProvider.family<UsedAmountData, Tuple2<String, Ingredient>>((ref, tuple) async {
  final orderId = tuple.item1;
  final ingredient = tuple.item2;
  final boxKey = '$orderId-${ingredient.plu}';
  final box = Hive.box<UsedAmountData>('pouredAmountBox');
  var dataFromBox = box.get(boxKey);

  if (dataFromBox == null) {
    dataFromBox = UsedAmountData(date: '', usedAmount: 0);
  } else if (dataFromBox is Map<String, dynamic>) {
    dataFromBox = UsedAmountData.fromMap(dataFromBox as Map<String, dynamic>);
  }

  var data = dataFromBox;

  final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  if (data.date != currentDate) {
    data = UsedAmountData(date: '', usedAmount: 0);
    await box.put(boxKey, data);
  }

  return data;
});

final amountStateProvider =
    StateNotifierProvider.family<AmountStateNotifier, AmountState, Tuple2<String, Ingredient>>((ref, tuple) {
  final orderId = tuple.item1;
  final ingredient = tuple.item2;
  final requiredAmount = ingredient.percentage * ingredient.amountToProduce;
  return AmountStateNotifier(ref, orderId, ingredient, requiredAmount);
});

class AmountStateNotifier extends StateNotifier<AmountState> {
  AmountStateNotifier(this.ref, this.orderId, this.ingredient, this.requiredAmount)
      : super(AmountState(requiredAmount, 0)) {
    Future.microtask(_loadInitialUsedAmount);
  }
  final StateNotifierProviderRef<AmountStateNotifier, AmountState> ref;
  final Ingredient ingredient;
  final double requiredAmount;
  final String orderId;

  Future<void> _loadInitialUsedAmount() async {
    final data = await ref.read(usedAmountProvider(Tuple2(orderId, ingredient)).future);
    state = AmountState(requiredAmount, formatPrecision(data.usedAmount));
  }

  Future<void> updateUsedAmount(double newUsedAmount) async {
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final boxKey = '$orderId-${ingredient.plu}';
    final box = Hive.box<UsedAmountData>('pouredAmountBox');
    final updatedUsedAmount =
        UsedAmountData(date: currentDate, usedAmount: formatPrecision(state.usedAmount + newUsedAmount));
    await box.put(boxKey, updatedUsedAmount);
    state = AmountState(requiredAmount, updatedUsedAmount.usedAmount);
  }
}

final allIngredientsMeetConditionProvider =
    FutureProvider.family<bool, Tuple2<String, List<Ingredient>>>((ref, tuple) async {
  final orderId = tuple.item1;
  final ingredients = tuple.item2;

  for (final ingredient in ingredients) {

    // Watch the amountStateProvider for the ingredient
    final amountState = ref.watch(amountStateProvider(Tuple2(orderId, ingredient)));

    final usedAmount = amountState.usedAmount;

    // Check the condition based on usedAmount from amountState
    if (usedAmount < (0.998 * ingredient.amountToProduce * ingredient.percentage)) {
      return false;
    }
  }

  return true;
});

final ingredientsByProductNameProvider = Provider.family<List<Ingredient>, String>((ref, productName) {
  final productListAsyncValue = ref.watch(consolidatedProductListProvider);

  var productList = <ProductDisplayData>[];

  // Ensure data is loaded
  if (productListAsyncValue is AsyncData<List<ProductDisplayData>>) {
    productList = productListAsyncValue.value;
  } else {
    // Handle other states if necessary, like showing an error or a loading indicator.
    return [];
  }

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

  return []; // Return an empty list if no matching product is found
});

final refreshTriggerProvider = StateProvider<bool>((ref) => false);


final ingredientRepositoryProvider =
Provider<IngredientRepository>((ref) => IngredientRepository(FirebaseFirestore.instance));

final ingredientBoxProvider = StateProvider<Box<IngredientState>>((ref) => Hive.box<IngredientState>('ingredientBox'));

final ingredientProvider = StreamProvider.autoDispose.family<IngredientState, String>((ref, ingredientPLU) async* {
  final box = ref.watch(ingredientBoxProvider);

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
