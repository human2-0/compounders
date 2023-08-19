import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/repository/ingredients_repository.dart';
import 'package:flutter/material.dart';

import '../models/mixers_models.dart';
import 'pouring_progress_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PouringScreen extends ConsumerStatefulWidget {
  final Ingredient ingredient;

  const PouringScreen({super.key, required this.ingredient});

  @override
  PouringScreenState createState() => PouringScreenState();
}

class PouringScreenState extends ConsumerState<PouringScreen> {
  final TextEditingController _controller = TextEditingController();
  double userValue = 0;
  bool isStockUpdated = false;

  @override
  Widget build(BuildContext context) {
    final double requiredAmount =
        widget.ingredient.percentage * widget.ingredient.amountToProduce;

    final ingredientAsyncValue =
        ref.watch(ingredientProvider(widget.ingredient.plu));

    return ingredientAsyncValue.when(
      data: (ingredientSnapshot) {
        return Scaffold(
          backgroundColor: Colors.black, // Set background to black
          appBar: PreferredSize(
            preferredSize:
                const Size.fromHeight(30.0), // Set the desired height
            child: AppBar(
              backgroundColor: Colors.black, // Set AppBar background to black
              leadingWidth: 30,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back,
                    size: 15.0, color: Colors.white), // Adjust icon size here
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Center(
                  child: Text(widget.ingredient.name,
                      style: const TextStyle(
                          color: Colors.white))), // Adjust text color here
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Container to display the required amount
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${requiredAmount.toStringAsFixed(3)} kg',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 20)),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.60,
                  height: MediaQuery.sizeOf(context).height *
                      0.15, // for 50% of screen width
                  child: TextField(
                    controller: _controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onSubmitted: (value) {
                      setState(() {
                        userValue = double.parse(value);
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
                PouringProgressBar(
                    requiredAmount: requiredAmount, value: userValue),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: IconButton(
                              key: ValueKey<bool>(
                                  isStockUpdated), // This key ensures the widget rebuilds when the value changes
                              icon: isStockUpdated
                                  ? const Icon(Icons.oil_barrel_rounded)
                                  : const Icon(Icons.water_drop_outlined),
                              color: isStockUpdated
                                  ? Colors.yellow
                                  : Colors
                                      .white, // Changing color based on the flag
                              onPressed: isStockUpdated
                                  ? () {
                                      setState(() {
                                        isStockUpdated = false;
                                      });
                                      // Logic for what happens when the barrel icon is pressed
                                      // For example, show some details about the barrel or navigate to another screen
                                    }
                                  : () async {
                                      try {
                                        double usedAmount =
                                            double.parse(_controller.text);

                                        final ingredientRepo = ref
                                            .read(ingredientRepositoryProvider);

                                        await ingredientRepo.pourIngredient(widget.ingredient.plu,
                                            usedAmount,
                                            requiredAmount);

                                        IngredientLog log = IngredientLog(
                                          userId: "human2-0",
                                          productName:
                                              widget.ingredient.productName,
                                          ingredientId: widget.ingredient.plu,
                                          ingredientName:
                                              widget.ingredient.name,
                                          usedAmount: usedAmount,
                                          requiredAmount: requiredAmount,
                                          userValue: userValue,
                                        );

                                        await ingredientRepo
                                            .productLogIngredients(log);

                                        // Once the data is updated and logged, change the state of the flag
                                        setState(() {
                                          isStockUpdated = true;
                                        });
                                      } catch (e) {
                                        print(e);
                                      }
                                    },
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: MediaQuery.of(context).size.width * 0.25,
                            decoration: BoxDecoration(
                              color: isStockUpdated
                                  ? Colors.amber
                                  : Colors.blueGrey,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: Center(
                                child: Text(isStockUpdated ? 'Check' : 'Pour',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11))),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: IconButton(
                              icon:
                                  const Icon(Icons.add_shopping_cart_outlined),
                              color: Colors.white,
                              onPressed: () {
                                // your functionality goes here
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
                            child: const Center(
                                child: Text('Top up',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11))),
                          ),
                        ],
                      ),
                    ),
                    Container(
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
                                  child: Text('Scale',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, _) => Text('Error loading ingredient: $error'),
    );
  }
}
