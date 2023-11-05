import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/models/used_amount_model.dart';
import 'package:compounders/providers/ingredients_provider.dart';
import 'package:compounders/repository/ingredients_repository.dart';
import 'package:compounders/screens/compounding/compounding/pouring_progress_bar.dart';
import 'package:compounders/screens/compounding/compounding/use_whole_barrel.dart';
import 'package:compounders/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

class PouringScreen extends ConsumerStatefulWidget {
  const PouringScreen({required this.ingredient, required this.orderId, super.key});
  final Ingredient ingredient;
  final String orderId;

  @override
  PouringScreenState createState() => PouringScreenState();
}

class PouringScreenState extends ConsumerState<PouringScreen> {
  late TextEditingController _controller;
  double userValue = 0;
  late bool isPoured;

  double usedAmount = 0;

  double overUsedAmount = 0;

  @override
  void initState() {
    super.initState();
    Future(() => ref.read(selectedIngredientProvider.notifier).state = widget.ingredient);
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var isPoured = ref.watch(isPouredProvider.notifier).state;
    final requiredAmount = widget.ingredient.percentage * widget.ingredient.amountToProduce;
    final addedAmount =
        formatPrecision(ref.watch(amountStateProvider(Tuple2(widget.orderId, widget.ingredient))).usedAmount);

    final ingredientAsyncValue = ref.watch(ingredientProvider(widget.ingredient.plu));

    final ingredientRepo = ref.read(ingredientRepositoryProvider);

    Future<void> updateUsedAmount(WidgetRef ref, String orderId, Ingredient ingredient, double newUsedAmount) async {
      final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final boxKey = '$orderId-${ingredient.plu}';
      final updatedUsedAmount = addedAmount + newUsedAmount;

      final box = Hive.box<UsedAmountData>('pouredAmountBox'); // Accessing box directly
      final updatedUsedAmountData = UsedAmountData(date: currentDate, usedAmount: formatPrecision(updatedUsedAmount));
      await box.put(boxKey, updatedUsedAmountData);

      await ref.read(amountStateProvider(Tuple2(orderId, ingredient)).notifier).updateUsedAmount(newUsedAmount);
    }

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
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Center(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(widget.ingredient.name, style: const TextStyle(color: Colors.white)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(' in use: \n ${ingredientSnapshot.currentBarrel}',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
              ],
            )), // Adjust text color here
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              // Container to display the required amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${formatPrecision(requiredAmount - addedAmount)} left to add',
                        style: const TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.70,
                height: MediaQuery.sizeOf(context).height * 0.15, // for 50% of screen width
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (value) {
                    setState(() {
                      try {
                        userValue = double.parse(value);
                      } on FormatException catch (e) {debugPrint('error');}
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center, // Text color
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Enter Amount',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey.shade800,
                    // Dark Grey color fill
                  ),
                ),
              ),
              PouringProgressBar(requiredAmount: requiredAmount, value: userValue),
              const SizedBox(
                height: 4,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: GestureDetector(
                            onLongPress: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => UseWholeBarrel(
                                          ingredient: widget.ingredient,
                                          requiredAmount: requiredAmount - addedAmount,
                                          stock: ingredientSnapshot.stock,
                                          orderId: widget.orderId,
                                        )),
                              );
                            },
                            child: IconButton(
                              key: ValueKey<bool>(
                                  isPoured), // This key ensures the widget rebuilds when the value changes
                              icon: isPoured
                                  ? const Icon(Icons.oil_barrel_rounded)
                                  : const Icon(Icons.water_drop_outlined),
                              color:
                                  _controller.text.isNotEmpty ? (isPoured ? Colors.yellow : Colors.white) : Colors.grey,

                              onPressed: isPoured
                                  ? () async {
                                      try {
                                        if (!_controller.text.isNotEmpty) return;
                                        await ingredientRepo.adjustCurrentBarrelWeight(ingredientSnapshot, userValue,
                                            widget.ingredient.plu, usedAmount, requiredAmount);

                                        var wastedAmount = 0.0;
                                        final adjustedNetWeightOfBarrel = userValue - ingredientSnapshot.tareWeight;
                                        final difference = ((ingredientSnapshot.currentBarrel -
                                                        adjustedNetWeightOfBarrel -
                                                        requiredAmount) *
                                                    1000)
                                                .roundToDouble() /
                                            1000;

                                        wastedAmount = difference;

                                        final log = IngredientLog(
                                          userId: 'human2-0',
                                          productName: widget.ingredient.productName,
                                          ingredientId: widget.ingredient.plu,
                                          ingredientName: widget.ingredient.name,
                                          usedAmount: usedAmount,
                                          wastedAmount: wastedAmount.abs(),
                                          overUsedAmount: overUsedAmount.abs(),
                                        );

                                        await ingredientRepo.productLogIngredients(log);

                                        setState(() {
                                          ref.watch(isPouredProvider.notifier).state = false;
                                        });
                                        _controller.clear();
                                        userValue = 0;
                                        ref.read(refreshTriggerProvider.notifier).state =
                                            !ref.read(refreshTriggerProvider.notifier).state;
                                      } on FormatException catch (e) {debugPrint('error');}
                                      // Logic for what happens when the barrel icon is pressed
                                      // For example, show some details about the barrel or navigate to another screen
                                    }
                                  : () async {
                                      if (!_controller.text.isNotEmpty) return;
                                      try {
                                        // Once the used provides poured amount, update state of necessary properties
                                        setState(() {
                                          isPoured = true;
                                          usedAmount = userValue;
                                          if ((requiredAmount - usedAmount).isNegative) {
                                            overUsedAmount = requiredAmount - usedAmount;
                                          }
                                          ref.read(isPouredProvider.notifier).state = true;
                                          updateUsedAmount(ref, widget.orderId, widget.ingredient, usedAmount);
                                          _controller.clear();
                                        });
                                      } on FormatException catch (e) {debugPrint('error');}
                                    },
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: MediaQuery.of(context).size.width * 0.25,
                          decoration: BoxDecoration(
                            color: isPoured ? Colors.amber : Colors.blueGrey,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                          ),
                          child: Center(
                              child: Text(isPoured ? 'Check' : 'Pour',
                                  style: TextStyle(
                                      color: _controller.text.isNotEmpty ? Colors.white : Colors.grey, fontSize: 11))),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                            color: Colors.white,
                            onPressed: () async {
                              await _showConfirmationDialog(
                                context,
                                ref,
                                ingredientSnapshot,
                                widget.ingredient.plu,
                                usedAmount,
                                overUsedAmount,
                                userValue,
                                requiredAmount,
                                widget.ingredient.productName,
                                widget.ingredient.name,
                              );
                            },
                          ),
                        ),
                        Container(
                          width: MediaQuery.sizeOf(context).width * 0.25,
                          decoration: const BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                          ),
                          child:
                              const Center(child: Text('Top up', style: TextStyle(color: Colors.white, fontSize: 11))),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.scale_rounded),
                          color: Colors.white,
                          onPressed: () {
                            // your functionality goes here
                          },
                        ),
                        Container(
                            width: MediaQuery.sizeOf(context).width * 0.25,
                            decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: const Center(
                                child: Text('Scale', style: TextStyle(color: Colors.white, fontSize: 11)))),
                      ],
                    ),
                  ),
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

Future<void> _showConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    IngredientState ingredientSnapshot,
    String ingredientPLU,
    double usedAmount,
    double overUsedAmount,
    double userValue,
    double requiredAmount,
    String productName,
    String ingredientName) async {
  final height = MediaQuery.of(context).size.height;

  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (context) => Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
        ),
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: AppBar(
            title: Text(
              'Confirmation',
              style: TextStyle(fontSize: 0.04 * height),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, size: 15),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Do you want to start using a new barrel and save the remaining amount as waste?',
                style: TextStyle(fontSize: 0.05 * height),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: Text('Proceed', style: TextStyle(fontSize: 0.03 * height)),
                onPressed: () async {
                  // Call your topUpIngredient method here
                  Navigator.of(context).pop();
                  await _showWeightsInputDialog(context, ref, ingredientSnapshot, ingredientPLU, userValue, usedAmount,
                      overUsedAmount, requiredAmount, productName, ingredientName);
                },
              ),
            ],
          ),
        ),
      ),
    ),
    fullscreenDialog: true,
  ));
}

Future<void> _showWeightsInputDialog(
    BuildContext context,
    WidgetRef ref,
    IngredientState ingredientSnapshot,
    String ingredientPLU,
    double userValue,
    double usedAmount,
    double overUsedAmount,
    double requiredAmount,
    String productName,
    String ingredientName) async {
  final height = MediaQuery.of(context).size.height;

  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (dialogContext) {
      double? newTareWeight;
      double? newBarrelWeight;

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
                        if (newTareWeight == null ||
                            newTareWeight == 0 ||
                            newBarrelWeight == null ||
                            newBarrelWeight == 0) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                              'Please enter valid weights',
                              style: TextStyle(fontSize: 8),
                            )),
                          );
                          return;
                        }
                        var wastedAmount = 0.0;
                        final adjustedNetWeightOfBarrel = userValue - ingredientSnapshot.tareWeight;
                        var difference = adjustedNetWeightOfBarrel - ingredientSnapshot.currentBarrel;

                        if (difference < 0) {
                          difference = (difference * 1000).roundToDouble() / 1000;
                          wastedAmount = difference;
                        }

                        if (ref.watch(isPouredProvider)) {
                          await ref
                              .read(ingredientRepositoryProvider)
                              .pourIngredient(ingredientPLU, usedAmount, requiredAmount, difference);

                          final log = IngredientLog(
                            userId: 'human2-0',
                            productName: productName,
                            ingredientId: ingredientPLU,
                            ingredientName: ingredientName,
                            usedAmount: usedAmount,
                            wastedAmount: wastedAmount.abs(),
                            overUsedAmount: overUsedAmount,
                          );

                          await ref.read(ingredientRepositoryProvider).productLogIngredients(log);
                        }

                        // Logic for updating with newTareWeight and newBarrelWeight
                        // Call your topUpIngredient function here
                        await ref.read(ingredientRepositoryProvider).topUpIngredient(
                              currentBarrelWeight: ingredientSnapshot.currentBarrel,
                              newTareWeight: newTareWeight ?? 0,
                              newBarrelWeight: newBarrelWeight ?? 0,
                              ingredientPLU: ingredientPLU,
                            );

                        final log = IngredientLog(
                          userId: 'human2-0',
                          productName: productName,
                          ingredientId: ingredientPLU,
                          ingredientName: ingredientName,
                          usedAmount: usedAmount,
                          wastedAmount: wastedAmount.abs(),
                          overUsedAmount: overUsedAmount,
                        );

                        await ref.read(ingredientRepositoryProvider).productLogIngredients(log);

                        ref.watch(isPouredProvider.notifier).state = false;
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400], // background color
                      ),
                      child: Text('Cancel', style: TextStyle(fontSize: 0.03 * height)),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
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
    fullscreenDialog: true,
  ));
}
