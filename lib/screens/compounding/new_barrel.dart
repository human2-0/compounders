import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/providers/compounding_provider.dart';
import 'package:compounders/providers/ingredients_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// NewBarrel Widget
///
/// A widget that presents an interface for the user to submit new weights for a new opened barrel.
/// It handles the logic of submitting this data to a repository
/// and navigating to a different screen based on the user's actions.
class NewBarrel extends ConsumerStatefulWidget {
  // ignore: public_member_api_docs
  const NewBarrel({super.key});

  @override
  IssueNewBarrelWeightsState createState() => IssueNewBarrelWeightsState();
}

// ignore: public_member_api_docs
class IssueNewBarrelWeightsState extends ConsumerState<NewBarrel> {
  /// Submits new tare and contained amount weights for an ingredient.
  ///
  /// Performs validation on the weights, updates the ingredient data, logs the activity,
  /// and navigates to the pouring screen upon successful submission.
  ///
  /// Parameters:
  ///   - `newTareWeight`: The new tare weight to be registered.
  ///   - `newBarrelWeight`: The new barrel weight to be registered.
  ///   - `ingredientData`: The current state of the ingredient.
  Future<void> _submitData(double newTareWeight, double newBarrelWeight, IngredientState ingredientData) async {
    final ingredient = ref.watch(selectedIngredientProvider)!;
    final requiredAmount = ingredient.percentage * ingredient.amountToProduce;

    // Access the individual values from your state.
    final userValue = ref.watch(userValueProvider);
    final usedAmount = ref.watch(usedAmountStateProvider);
    final overUsedAmount = ref.watch(overusedAmountProvider);
    if (newTareWeight == 0 || newBarrelWeight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
          'Please enter valid weights',
          style: TextStyle(fontSize: 8),
        )),
      );
      return;
    }

    var wastedAmount = 0.0;
    final adjustedNetWeightOfBarrel = userValue - ingredientData.tareWeight;
    var difference = adjustedNetWeightOfBarrel - ingredientData.currentBarrel;

    if (difference < 0) {
      difference = (difference * 1000).roundToDouble() / 1000;
      wastedAmount = difference;
    }

    if (ref.watch(isPouredProvider)) {
      await ref
          .read(ingredientRepositoryProvider)
          .pourIngredient(ingredient.plu, usedAmount, requiredAmount, difference);

      final log = IngredientLog(
        userId: 'human2-0',
        productName: ingredient.productName,
        ingredientId: ingredient.plu,
        ingredientName: ingredient.name,
        usedAmount: usedAmount,
        wastedAmount: wastedAmount.abs(),
        overUsedAmount: overUsedAmount,
      );

      await ref.read(ingredientRepositoryProvider).productLogIngredients(log);
    }

    await ref.read(ingredientRepositoryProvider).topUpIngredient(
          currentBarrelWeight: ingredientData.currentBarrel,
          newTareWeight: newTareWeight,
          newBarrelWeight: newBarrelWeight,
          ingredientPLU: ingredient.plu,
        );

    final log = IngredientLog(
      userId: 'human2-0',
      productName: ingredient.productName,
      ingredientId: ingredient.plu,
      ingredientName: ingredient.name,
      usedAmount: usedAmount,
      wastedAmount: wastedAmount.abs(),
      overUsedAmount: overUsedAmount,
    );

    await ref.read(ingredientRepositoryProvider).productLogIngredients(log);

    ref.watch(isPouredProvider.notifier).state = false;
    // Navigate to pouring screen if the widget is still mounted after asynchronous operations.
    if (mounted) {
      GoRouter.of(context).go('/pouring');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final height = MediaQuery.of(context).size.height;
    final ingredient = ref.watch(selectedIngredientProvider)!;

    final ingredientSnapshot = ref.watch(ingredientProvider(ingredient.plu));
    return ingredientSnapshot.when(
      data: (ingredientData) {
        late double? newTareWeight;
        late double? newBarrelWeight;

        return Theme(
          data: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.black,
            inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(color: Colors.white),
              hintStyle: TextStyle(color: Colors.white70),
            ),
          ),
          child: Scaffold(
            key: scaffoldKey,
            body: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'New Tare Weight',
                      labelStyle: TextStyle(color: Colors.white),
                      hintStyle: TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      newTareWeight = double.tryParse(value);
                    },
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'New Barrel Weight',
                      labelStyle: TextStyle(color: Colors.white),
                      hintStyle: TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      newBarrelWeight = double.tryParse(value);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          child: Text('Submit', style: TextStyle(fontSize: 0.03 * height)),
                          onPressed: () async {
                            await _submitData(newTareWeight!, newBarrelWeight!, ingredientData);
                          }),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400], // background color
                        ),
                        child: Text('Cancel', style: TextStyle(fontSize: 0.03 * height)),
                        onPressed: () {
                          GoRouter.of(context).go('/pouring');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: CircularProgressIndicator.new, // Return a loading widget or any other placeholder
      error: (error, _) => Text('Error: $error'),
    );
  }
}
