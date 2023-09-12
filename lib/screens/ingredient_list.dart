
import 'package:compounders/repository/ingredients_repository.dart';
import 'package:compounders/screens/pouring.dart';
import 'package:compounders/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';
import '../models/ingredient_model.dart';
import '../models/mixers_models.dart';

class IngredientListScreen extends ConsumerStatefulWidget {
  final AssignedProduct assignedProduct;
  final String orderId;
  final String productName;
  final List<Ingredient> ingredientsList;

  const IngredientListScreen(
      {Key? key,
      required this.assignedProduct,
      required this.orderId,
      required this.productName,
      required this.ingredientsList})
      : super(key: key);

  @override
  IngredientListScreenState createState() => IngredientListScreenState();
}

class IngredientListScreenState extends ConsumerState<IngredientListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(30.0),
        child: AppBar(
          backgroundColor: Colors.black,
          leadingWidth: 30,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 15.0, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Center(
            child: Text(
              widget.productName,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: widget.ingredientsList.length,
        itemBuilder: (BuildContext context, int index) {
          final Ingredient currentIngredient = widget.ingredientsList[index];
          final String plu = currentIngredient.plu;
          final ingredientName = currentIngredient.name;
          final ingredientPercentage = currentIngredient.percentage;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return PouringScreen(
                        ingredient: currentIngredient, orderId: widget.orderId);
                  },
                ),
              );
            },
            child: Consumer(builder: (context, ref, child) {
              final amountState = ref.watch(amountStateProvider(
                  Tuple2(widget.orderId, currentIngredient)));
              final isCompleted = formatPrecision(amountState.usedAmount) >=
                  (0.998 * amountState.requiredAmount);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2.0),
                padding: const EdgeInsets.all(4.0),
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
                          isCompleted
                              ? Icons.science_rounded
                              : Icons.science_outlined,
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
                          'Amount: ${ingredientPercentage * widget.assignedProduct.amountToProduce} kg',
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
