import 'package:compounders/repository/ingredients_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

import '../models/ingredient_model.dart';

class IngredientsDoneCheck extends ConsumerWidget {
  final String orderId;
  final List<Ingredient> ingredientsList;

  const IngredientsDoneCheck({
    Key? key,
    required this.orderId,
    required this.ingredientsList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      error: (error, stackTrace) {
        // Handle error state. You can also show a text message or some other widget.
        return const Icon(
          Icons.error_outline,
          color: Colors.red,
        );
      },
      loading: () {
        // Show a loading state, for instance, a CircularProgressIndicator.
        return const CircularProgressIndicator();
      },
    );
  }
}
