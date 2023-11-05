import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/models/used_amount_model.dart';
import 'package:compounders/providers/ingredients_provider.dart';
import 'package:compounders/repository/ingredients_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

class UseWholeBarrel extends ConsumerWidget {

  const UseWholeBarrel({required this.ingredient, required this.requiredAmount, required this.stock, required this.orderId, super.key});
  final Ingredient ingredient;
  final double requiredAmount;
  final double stock;
  final String orderId;

  Future<void> updateUsedAmount(
      WidgetRef ref, Ingredient ingredient, double newUsedAmount) async {
    final box = Hive.box<UsedAmountData>('pouredAmountBox');

    // Create a UsedAmountData object with the current date and newUsedAmount
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dataToStore = UsedAmountData(date: currentDate, usedAmount: newUsedAmount);

    // Put the UsedAmountData object into the Hive box
    await box.put(ingredient.plu, dataToStore);

    await ref.watch(amountStateProvider(Tuple2(orderId, ingredient)).notifier).updateUsedAmount(newUsedAmount);
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late double tareWeight;
    late double barrelWeight;
    late double emptyBarrelWeight;
    const overUsedAmount = 0.0;
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
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(child: Text('Use whole barrel', style: TextStyle(fontSize: 10))),
              const SizedBox(height: 4,),
              SizedBox(
                height: 35,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tare Weight',
                    labelStyle: TextStyle(color: Colors.white),
                    hintStyle: TextStyle(color: Colors.white70),
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                    EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                    EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                      final wastedAmount = emptyBarrelWeight - tareWeight;
                      final usedAmount = barrelWeight - wastedAmount;
                      await ref.read(ingredientRepositoryProvider).pourWholeBarrel(usedAmount, wastedAmount, ingredient.plu);

                      await updateUsedAmount(ref,
                          ingredient, usedAmount);



                        final log = IngredientLog(
                          userId: 'human2-0',
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
