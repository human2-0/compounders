import 'package:compounders/providers/ingredients_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

/// `IngredientsDoneCheck` displays an icon indicating whether all ingredients for a product are ready.
///
/// It subscribes to ingredient-related state providers using Riverpod to determine if all conditions
/// for the product's ingredients have been met based on the given `orderId`. It shows a green checkmark
/// if all ingredients are ready, a red checkmark if not, an error icon on error, and a loading indicator
/// while the check is in progress.
///
/// Parameters:
///   - `orderId`: A [String] that represents the unique identifier for the order.
///   - `productName`: A [String] that represents the name of the product for which ingredients are being checked.
///   - `key`: An optional [Key] used to control how one widget replaces another widget in the tree.
class IngredientsDoneCheck extends ConsumerWidget {

  /// Constructs an `IngredientsDoneCheck` widget.
  ///
  /// Receives an [orderId] and a [productName] required for checking ingredient status,
  /// and an optional [Key] to uniquely identify the widget in the tree.
  const IngredientsDoneCheck({
    required this.orderId,
    required this.productName,
    super.key,
  });
  /// The unique identifier for the order.
  final String orderId;

  /// The name of the product for which ingredients are being checked.
  final String productName;

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
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('orderId', orderId))
    ..add(StringProperty('productName', productName));
  }
}
