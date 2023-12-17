import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/providers/compounding_provider.dart';
import 'package:compounders/providers/ingredients_provider.dart';
import 'package:compounders/providers/products_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuple/tuple.dart';

//TODO: please add IconButton to revert parameters to initial state when isPoured=true, if user click on red cancel button
/// A stateful widget that provides an interactive button to handle pouring actions
/// related to a specific ingredient. It allows for recording the used amount of an
/// ingredient and provides feedback on the action's success.
class PouringActionButton extends ConsumerStatefulWidget {
  ///Expecting a two parameters coming from compounding.dart, where ingredientSnapshot is retrieved from the AsyncValue iteration.
  const PouringActionButton({
    required this.ingredientSnapshot,
    required this.controller,
    super.key,
  });

  /// The state of the ingredient being poured, including its current stock and tare weight.
  final IngredientState ingredientSnapshot;

  /// A controller for the text field that accepts the poured amount input from the user.
  final TextEditingController controller;

  @override
  PouringActionButtonState createState() => PouringActionButtonState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IngredientState>('ingredientSnapshot', ingredientSnapshot))
      ..add(DiagnosticsProperty<TextEditingController>('controller', controller));
  }
}

// ignore: public_member_api_docs
class PouringActionButtonState extends ConsumerState<PouringActionButton> {
  /// Tracks if the ingredient has been poured.
  late bool isPoured;

  /// Indicates if the pouring action was successful.
  bool isSuccessful = false;

  /// The total amount of ingredient used.
  double usedAmount = 0;

  /// The amount of ingredient used over the required amount.
  double overUsedAmount = 0;

  @override
  void initState() {
    super.initState();
    isPoured = false;
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            // AnimatedSwitcher for a smooth transition between button states.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: GestureDetector(
                onLongPress: _useWholeIngredient,
                child: IconButton(
                  key: ValueKey<bool>(isPoured),
                  icon: _buildIcon(),
                  color: _getIconButtonColor(),
                  onPressed: isPoured ? _handleIngredientCheckAction : _handlePourAction,
                ),
              ),
            ),
            _buildAnimatedContainer(),
          ],
        ),
      );

  Future<void> _useWholeIngredient() async {
    ref.read(ingredientStockProvider.notifier).state = widget.ingredientSnapshot.stock;
    await GoRouter.of(context).push('/use_all');
  }

  Icon _buildIcon() {
    if (isSuccessful) {
      return const Icon(Icons.check, color: Colors.green);
    } else if (isPoured) {
      return const Icon(Icons.oil_barrel_rounded);
    } else {
      return const Icon(Icons.water_drop_outlined);
    }
  }

  Color _getIconButtonColor() {
    if (widget.controller.text.isNotEmpty) {
      return isPoured ? Colors.yellow : Colors.white;
    }
    return Colors.grey;
  }

  AnimatedContainer _buildAnimatedContainer() => AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: MediaQuery.of(context).size.width * 0.25,
        decoration: BoxDecoration(
          color: isSuccessful
              ? Colors.green
              : isPoured
                  ? Colors.amber
                  : Colors.blueGrey,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: Center(
          child: Text(
            isSuccessful
                ? 'Done'
                : isPoured
                    ? 'Check'
                    : 'Pour',
            style: TextStyle(
              color: isSuccessful
                  ? Colors.lightGreenAccent
                  : widget.controller.text.isNotEmpty
                      ? Colors.white
                      : isPoured
                          ? Colors.yellowAccent
                          : Colors.grey,
              fontSize: 11,
            ),
          ),
        ),
      );

  /// Handles the action for checking and adjusting the ingredient.
  ///
  /// This method is triggered when the user interacts with the UI element
  /// (such as pressing a button) intended for checking or adjusting the ingredient.
  /// It performs a series of operations including verifying user input,
  /// adjusting ingredient quantities, and updating the UI state.
  Future<void> _handleIngredientCheckAction() async {
    // Check if the text controller for user input is not empty.
    // If it is empty, no further action is taken and the method exits early.
    if (!widget.controller.text.isNotEmpty) return;

    try {
      // Perform the ingredient adjustment operation.
      // This involves calling the _performIngredientAdjustment method which
      // contains the logic for adjusting the ingredient based on the user input.
      // This might include operations like updating the ingredient's weight,
      // calculating the used and wasted amounts, and logging these details.
      await _performIngredientAdjustment();

      // Update the UI state to reflect the success of the operation.
      // This is done by calling the _updateStateOnSuccess method, which
      // might change certain UI elements to indicate that the ingredient
      // adjustment was successful (like updating icons, text, colors, etc.).
      _updateStateOnSuccess();
    } on FormatException {
      // If a format exception occurs during the operation, it's caught here.
      // A format exception typically occurs if the format of the input data
      // is invalid. For example, if a string input is expected to be a number
      // but isn't, a FormatException would be thrown.
      // Here, the exception is logged to the console for debugging purposes.
      debugPrint('error');
    }
  }

  Future<void> _performIngredientAdjustment() async {
    final ingredientRepo = ref.read(ingredientRepositoryProvider);
    final ingredientSnapshot = widget.ingredientSnapshot;
    final ingredient = ref.watch(selectedIngredientProvider)!;
    final requiredAmount = ingredient.percentage * ingredient.amountToProduce;
    final userValue = ref.read(userValueProvider);

    try {
      // Adjust the current barrel weight
      await ingredientRepo.adjustCurrentBarrelWeight(
          ingredientSnapshot, userValue, ingredient.plu, usedAmount, requiredAmount);

      // Calculate wasted amount
      var wastedAmount = 0.0;
      final adjustedNetWeightOfBarrel = userValue - ingredientSnapshot.tareWeight;

      wastedAmount =
          ((ingredientSnapshot.currentBarrel - adjustedNetWeightOfBarrel - requiredAmount) * 1000).roundToDouble() /
              1000;

      // Log the ingredient usage
      final log = IngredientLog(
        userId: 'human2-0', // Replace with actual user ID
        productName: ingredient.productName,
        ingredientId: ingredient.plu,
        ingredientName: ingredient.name,
        usedAmount: usedAmount,
        wastedAmount: wastedAmount.abs(),
        overUsedAmount: overUsedAmount.abs(),
      );

      await ingredientRepo.productLogIngredients(log);
    } on Exception catch (e) {
      // Handle exceptions
      debugPrint('Error adjusting ingredient barrel weight: $e');
    }
  }

  void _updateStateOnSuccess() {
    setState(() {
      isSuccessful = true;
    });

    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      setState(() {
        ref.read(isPouredProvider.notifier).state = false;
        isPoured = false;
        isSuccessful = false;
      });
    });
    widget.controller.clear();
    ref.read(userValueProvider.notifier).state = 0;
    ref.read(refreshTriggerProvider.notifier).state = !ref.read(refreshTriggerProvider.notifier).state;
    ref.read(usedAmountStateProvider.notifier).state = usedAmount;
    ref.read(overusedAmountProvider.notifier).state = overUsedAmount;
  }

  Future<void> _handlePourAction() async {
    if (!widget.controller.text.isNotEmpty) return;
    try {
      setState(() {
        isPoured = true;
        usedAmount = ref.read(userValueProvider);

        if ((ref.read(requiredAmountProvider) - usedAmount).isNegative) {
          overUsedAmount = ref.read(requiredAmountProvider) - usedAmount;
        }
        ref.read(isPouredProvider.notifier).state = true;
        ref.read(updateUsedAmountProvider(
            Tuple4(ref, ref.read(orderIdProvider), ref.watch(selectedIngredientProvider)!, usedAmount)));

        ref.read(userValueProvider.notifier).state = ref.read(userValueProvider);
        ref.read(usedAmountStateProvider.notifier).state = usedAmount;
        ref.read(overusedAmountProvider.notifier).state = overUsedAmount;
        widget.controller.clear();
      });
    } on FormatException {
      debugPrint('error');
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('isPoured', isPoured))
      ..add(DiagnosticsProperty<bool>('isSuccessful', isSuccessful))
      ..add(DoubleProperty('usedAmount', usedAmount))
      ..add(DoubleProperty('overUsedAmount', overUsedAmount));
  }
}
