import 'package:compounders/providers/ingredients_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

class IngredientsDoneCheck extends ConsumerWidget {
  const IngredientsDoneCheck({
    required this.orderId,
    required this.productName,
    // required this.ingredientsList,
    super.key,
  });
  final String orderId;
  final String productName;
  // final List<Ingredient> ingredientsList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsList = ref.watch(ingredientsByProductNameProvider(productName));
    final check = ref.watch(allIngredientsMeetConditionProvider(Tuple2(orderId, ingredientsList)));

    return check.when(
      data: (data) {
        if (data) {
          // Return green icon when data is true.
          return const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
          );
        } else {
          // Return red icon when data is false.
          return const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.red,
          );
        }
      },
      error: (error, stackTrace) => const Icon(
        Icons.error_outline,
        color: Colors.red,
      ),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
