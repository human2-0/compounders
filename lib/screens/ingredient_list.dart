
import 'package:compounders/screens/pouring.dart';
import 'package:flutter/material.dart';
import '../models/mixers_models.dart';

class IngredientListScreen extends StatefulWidget {
  final ProductDetails product;
  final int amountToProduce;
  final String productName;

  const IngredientListScreen({Key? key, required this.product, required this.amountToProduce, required this.productName}) : super(key: key);

  @override
  IngredientListScreenState createState() => IngredientListScreenState();
}

class IngredientListScreenState extends State<IngredientListScreen> {
  List<bool> _selectedIngredients = [];

  @override
  void initState() {
    super.initState();
    _selectedIngredients = List<bool>.generate(
        widget.product.productFormula.length, (index) => false);
  }

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
            icon: const Icon(Icons.arrow_back,
                size: 15.0, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Center(
            child: Text(
              widget.product.productName,
              style: const TextStyle(
                  fontSize: 12, color: Colors.white),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: widget.product.productFormula.length,
        itemBuilder: (BuildContext context, int index) {
          final MapEntry pluEntry = widget.product.productFormula.entries.elementAt(index);
          final String plu = pluEntry.key;
          final ingredientDetails = pluEntry.value;
          final ingredientName = ingredientDetails["ingredientName"];
          final ingredientPercentage = ingredientDetails["percentage"];

          final Ingredient currentIngredient = Ingredient(
            plu: plu,
            name: ingredientName,
            percentage: ingredientPercentage,
            amountToProduce: widget.amountToProduce,
            productName: widget.productName,

          );

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PouringScreen(ingredient: currentIngredient),
                ),
              );
            },
            child: Container(
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
                        _selectedIngredients[index]
                            ? Icons.science_rounded
                            : Icons.science_outlined,
                        color: _selectedIngredients[index]
                            ? Colors.green
                            : Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedIngredients[index] =
                          !_selectedIngredients[index];
                        });
                      },
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
                        'Amount: ${ingredientPercentage * widget.amountToProduce} kg',
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
            ),
          );
        },
      ),
    );
  }
}