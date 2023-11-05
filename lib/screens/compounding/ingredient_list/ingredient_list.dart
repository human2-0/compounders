import 'package:compounders/providers/ingredients_provider.dart';
import 'package:compounders/providers/products_provider.dart';
import 'package:compounders/screens/compounding/compounding/pouring.dart';
import 'package:compounders/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

class IngredientListScreen extends ConsumerStatefulWidget {
  const IngredientListScreen({super.key});

  @override
  IngredientListScreenState createState() => IngredientListScreenState();
}

class IngredientListScreenState extends ConsumerState<IngredientListScreen> {
  @override
  Widget build(BuildContext context) {
    final orderId = ref.watch(orderIdProvider);
    final productName = ref.watch(selectedProductProvider);
    final ingredientsList = ref.watch(ingredientsByProductNameProvider(productName));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: AppBar(
          backgroundColor: Colors.black,
          leadingWidth: 30,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 15, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Center(
            child: Text(
              productName,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: ingredientsList.length,
        itemBuilder: (context, index) {
          final currentIngredient = ingredientsList[index];
          final plu = currentIngredient.plu;
          final ingredientName = currentIngredient.name;
          final ingredientPercentage = currentIngredient.percentage;
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PouringScreen(ingredient: currentIngredient, orderId: orderId),
                ),
              );
            },
            child: Consumer(builder: (context, ref, child) {
              final amountState = ref.watch(amountStateProvider(Tuple2(orderId, currentIngredient)));
              final isCompleted = formatPrecision(amountState.usedAmount) >= (0.998 * amountState.requiredAmount);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 25,
                      child: IconButton(
                        iconSize: 20,
                        icon: Icon(
                          isCompleted ? Icons.science_rounded : Icons.science_outlined,
                          color: isCompleted ? Colors.green : Colors.red,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredientName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Amount: ${ingredientPercentage * currentIngredient.amountToProduce} kg',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'PLU: $plu',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
