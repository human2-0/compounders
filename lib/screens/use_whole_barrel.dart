import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

import '../models/ingredient_model.dart';
import '../repository/ingredients_repository.dart';
import '../utils.dart';

class UseWholeBarrel extends ConsumerWidget {
  Ingredient ingredient;
  double requiredAmount;
  double stock;
  String orderId;

  UseWholeBarrel({Key? key, required this.ingredient, required this.requiredAmount, required this.stock, required this.orderId}) : super(key: key);
  double tareWeight = 0;
  double barrelWeight = 0;
  double emptyBarrelWeight = 0;
  double overUsedAmount = 0;

  void updateUsedAmount(
      WidgetRef ref, Ingredient ingredient, double newUsedAmount) async {
    final box = await ref.read(pouredAmountBoxProvider.future);
    await box.put(ingredient.plu, newUsedAmount);

    final amountStateNotifier =
    ref.watch(amountStateProvider(Tuple2(orderId,ingredient)).notifier);
    amountStateNotifier.updateUsedAmount(newUsedAmount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.of(context).size.height;
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
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Text('Use whole barrel', style: TextStyle(fontSize: 10))),
              SizedBox(height: 4,),
              SizedBox(
                height: 35,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tare Weight',
                    labelStyle: TextStyle(color: Colors.white),
                    hintStyle: TextStyle(color: Colors.white70),
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70, width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    tareWeight = double.tryParse(value)!;
                  },
                ),
              ),
              SizedBox(
                height: 35,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Barrel Weight',
                    labelStyle: TextStyle(color: Colors.white),
                    hintStyle: TextStyle(color: Colors.white70),
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70, width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    barrelWeight = double.tryParse(value)!;
                  },
                ),
              ),
              SizedBox(
                height: 35,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Empty barrel weight',
                    labelStyle: TextStyle(color: Colors.white),
                    hintStyle: TextStyle(color: Colors.white70),
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70, width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    emptyBarrelWeight = double.tryParse(value)!;
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    child: Text('Submit',
                        style: TextStyle(fontSize: 0.03 * height)),
                    onPressed: () async {
                      if (tareWeight == 0 ||
                          barrelWeight == 0 ||
                          emptyBarrelWeight == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                'Please enter valid weights',
                                style: TextStyle(fontSize: 8),
                              )),
                        );
                        return;
                      }
                      double wastedAmount = emptyBarrelWeight - tareWeight;
                      double usedAmount = barrelWeight - wastedAmount;
                      ref.read(ingredientRepositoryProvider).pourWholeBarrel(usedAmount, wastedAmount, ingredient.plu);

                      updateUsedAmount(ref,
                          ingredient, usedAmount);



                        IngredientLog log = IngredientLog(
                          userId: "human2-0",
                          productName: ingredient.productName,
                          ingredientId: ingredient.plu,
                          ingredientName: ingredient.name,
                          usedAmount: usedAmount,
                          wastedAmount: wastedAmount.abs(),
                          overUsedAmount: overUsedAmount.abs(),
                        );

                        await ref
                            .read(ingredientRepositoryProvider)
                            .productLogIngredients(log);

                      Navigator.of(context).pop();
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400], // background color
                    ),
                    child: Text('Cancel',
                        style: TextStyle(fontSize: 0.03 * height)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
