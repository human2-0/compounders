import 'package:compounders/models/product_model.dart';
import 'package:compounders/repository/products_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ingredient_model.dart';
import '../models/mixers_models.dart';
import 'ingredients_done_check.dart';
import 'ingredient_list.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final Map<String, AssignedProduct> products;
  final String? mixerName;

  const ProductListScreen({super.key, required this.products, this.mixerName});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final productsDetails = ref.read(productsRepository);

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
              child: Text('${widget.mixerName}',
                  style: const TextStyle(color: Colors.white))),
        ),
      ),
      body: ListView.builder(
        itemCount: widget.products.length,
        itemBuilder: (BuildContext context, int index) {
          String orderId = widget.products.keys.elementAt(index);
          AssignedProduct assignedProduct = widget.products[orderId]!;

          return FutureBuilder<ProductDetails>(
            future: productsDetails.getProductDetails(
                widget.mixerName!, assignedProduct.productId, orderId),
            builder:
                (BuildContext context, AsyncSnapshot<ProductDetails> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  // Log or display the error
                  return const Text("Error occurred!");
                }

                if (snapshot.hasData) {
                  final productData =
                      snapshot.data!; // Avoid using snapshot.data! repeatedly

                  List<Ingredient> ingredientsList =
                      productData.productFormula.entries.map((entry) {
                    var plu = entry.key;
                    var ingredientData = entry.value;

                    return Ingredient(
                      plu: plu, // defaults to an empty string if null
                      name: ingredientData[
                          'ingredientName'], // defaults to an empty string if null
                      percentage:
                          ingredientData['percentage'], // default to 0 if null
                      amountToProduce: assignedProduct.amountToProduce,
                      productName: productData.productName,
                    );
                  }).toList();


                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IngredientListScreen(
                              orderId: orderId,
                              assignedProduct: assignedProduct,
                              productName: productData.productName,
                              ingredientsList: ingredientsList),
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
                         IngredientsDoneCheck(orderId: orderId, ingredientsList: ingredientsList),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productData
                                    .productName, // Using fetched productName
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                              Text(
                                'to make: ${assignedProduct.amountToProduce.toString()} kg',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return ListTile(
                    title: Text('Error: ${snapshot.error}'),
                  );
                }
              }
              // While data is loading:
              return Center(
                  child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircularProgressIndicator(),
              ));
            },
          );
        },
      ),
    );
  }
}
