import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/models/used_amount_model.dart';
import 'package:compounders/providers/ingredients_provider.dart';
import 'package:compounders/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

final ingredientStockProvider = StateProvider<double>((ref) => 0.0);

final userValueProvider = StateProvider<double>((ref) => 0.0);
final usedAmountStateProvider = StateProvider<double>((ref) => 0.0);
final overusedAmountProvider = StateProvider<double>((ref) => 0.0);

final updateUsedAmountProvider =
    Provider.family<void, Tuple4<WidgetRef, String, Ingredient, double>>((ref, values) async {
  final widgetRef = values.item1;
  final orderId = values.item2;
  final ingredient = values.item3;
  final newUsedAmount = values.item4;

  final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final boxKey = '$orderId-${ingredient.plu}';
  final addedAmount = formatPrecision(ref.watch(amountStateProvider(Tuple2(orderId, ingredient))).usedAmount);
  final updatedUsedAmount = addedAmount + newUsedAmount; // Ensure 'addedAmount' is accessible

  final box = Hive.box<UsedAmountData>('pouredAmountBox');
  final updatedUsedAmountData = UsedAmountData(date: currentDate, usedAmount: formatPrecision(updatedUsedAmount));
  await box.put(boxKey, updatedUsedAmountData);

  await widgetRef.read(amountStateProvider(Tuple2(orderId, ingredient)).notifier).updateUsedAmount(newUsedAmount);
});

final requiredAmountProvider = StateProvider<double>((ref) {
  final ingredient = ref.watch(selectedIngredientProvider)!;
  final requiredAmount = ingredient.percentage * ingredient.amountToProduce;
  return requiredAmount;
});
