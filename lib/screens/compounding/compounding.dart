import 'package:compounders/providers/compounding_provider.dart';
import 'package:compounders/providers/ingredients_provider.dart';
import 'package:compounders/providers/products_provider.dart';
import 'package:compounders/screens/compounding/pouring_button.dart';
import 'package:compounders/screens/compounding/scale_button.dart';
import 'package:compounders/screens/compounding/top_up_button.dart';
import 'package:compounders/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuple/tuple.dart';

/// `PouringScreen` allows the user to record the amount of an ingredient being used in the production process.
///
/// It presents an interface for the user to enter the amount poured and displays the remaining required amount.
/// A progress bar visually represents how much of the ingredient has been poured relative to the required amount.
/// The screen also provides buttons for additional actions like topping up the ingredient, using whole ingredient container or selecting the scale.
///
/// Parameters:
///   - `key`: A [Key] used to control how one widget replaces another widget in the tree.

class CompoundingScreen extends ConsumerStatefulWidget {
  /// Constructs a `PouringScreen` widget.
  const CompoundingScreen({super.key});

  @override
  CompoundingScreenState createState() => CompoundingScreenState();
}

/// State class for `PouringScreen`.
///
/// Manages the text controller for input, tracks if pouring is successful, and holds the user-entered value.
/// Also manages the lifecycle of the text controller.
class CompoundingScreenState extends ConsumerState<CompoundingScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _textController;


  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = ref.watch(orderIdProvider);
    final ingredient = ref.watch(selectedIngredientProvider)!;
    final requiredAmount = ingredient.percentage * ingredient.amountToProduce;
    final addedAmount = formatPrecision(ref.watch(amountStateProvider(Tuple2(orderId, ingredient))).usedAmount);

    final ingredientAsyncValue = ref.watch(ingredientProvider(ingredient.plu));
    return ingredientAsyncValue.when(
      data: (ingredientSnapshot) => Scaffold(
        backgroundColor: Colors.black, // Set background to black
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(30), // Set the desired height
          child: AppBar(
            backgroundColor: Colors.black, // Set AppBar background to black
            leadingWidth: 30,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 15, color: Colors.white), // Adjust icon size here
              onPressed: () => GoRouter.of(context).pop(),
            ),
            title: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(ingredient.name, style: const TextStyle(color: Colors.white)),
            ), // Adjust text color here
            actions: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('In barrel', style: TextStyle(color: Colors.white, fontSize: 10)),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Text('${ingredientSnapshot.currentBarrel}',
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              // Container to display the required amount
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('To add', style: TextStyle(color: Colors.white, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text('${formatPrecision(requiredAmount - addedAmount)}',
                          style: const TextStyle(color: Colors.white, fontSize: 20)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),

              ///This is a temporary widget for getting poured value, in real use case it will be depreciated with
              ///listening to websocket from IoT scale, so the value will not be parsed from keyboard controller as it's now
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.70,
                height: MediaQuery.sizeOf(context).height * 0.15, // for 50% of screen width
                child: TextField(
                  controller: _textController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (value) {
                    setState(() {
                      try {
                        // Update the WeightsInputState
                        ref.read(userValueProvider.notifier).state = double.parse(value);
                      } on FormatException {
                        debugPrint('error');
                      }
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center, // Text color
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                    labelText: 'SCALE VALUE',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey.shade800,
                    // Dark Grey color fill
                  ),
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PouringActionButton(controller: _textController, ingredientSnapshot: ingredientSnapshot),
                  const TopUpButton(),
                  const ScaleButton(),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text('Error loading ingredient: $error', style: const TextStyle(fontSize: 6)),
    );
  }
}
