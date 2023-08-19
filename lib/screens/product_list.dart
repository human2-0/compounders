import 'package:compounders/repository/products_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mixers_models.dart';
import 'ingredient_list.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final List<Product> products;
  final String? mixerName;

  const ProductListScreen({super.key, required this.products, this.mixerName});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  List<bool> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _selectedProducts =
        List<bool>.generate(widget.products.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    final productsDetails = ref.watch(productsRepository);
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
          return FutureBuilder<ProductDetails>(
            future: productsDetails
                .getProductDetails(widget.products[index].productId),
            builder:
                (BuildContext context, AsyncSnapshot<ProductDetails> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  String productName = snapshot.data!.productName;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IngredientListScreen(product: snapshot.data!, amountToProduce: widget.products[index].amountToProduce, productName: productName),
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
                                _selectedProducts[index]
                                    ? Icons.flag_circle_rounded
                                    : Icons.flag_circle_outlined,
                                color: _selectedProducts[index]
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedProducts[index] =
                                      !_selectedProducts[index];
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName, // Using fetched productName
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                              Text(
                                'to make: ${widget.products[index].amountToProduce
                                    .toString()} kg',
                                style:
                                    const TextStyle(fontSize: 10, color: Colors.grey),
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
