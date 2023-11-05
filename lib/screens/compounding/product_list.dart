import 'package:compounders/providers/mixers_provider.dart';
import 'package:compounders/providers/products_provider.dart';
import 'package:compounders/screens/compounding/ingredient_list/ingredients_done_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});
  @override
  ProductListScreenState createState() => ProductListScreenState();
}

class ProductListScreenState extends ConsumerState<ProductListScreen> {
  @override
  Widget build(BuildContext context) {
    final productListAsyncValue = ref.watch(consolidatedProductListProvider);
    final mixerName = ref.watch(currentMixerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: AppBar(
          backgroundColor: Colors.black,
          title: Center(child: Text(mixerName, style: const TextStyle(color: Colors.white))),
        ),
      ),
      body: productListAsyncValue.when(
        data: (productDisplayList) {
          if (productDisplayList.isEmpty) {
            return const Center(child: Text('No products to display.')); // Added a case for empty list.
          }

          return ListView.builder(
            itemCount: productDisplayList.length,
            itemBuilder: (context, index) {
              final productDisplayData = productDisplayList[index];
              final productData = productDisplayData.productDetails;
              final assignedProduct = productDisplayData.product;
              final orderId = productDisplayData.queryData.orderId;
              return GestureDetector(
                onTap: () async {
                  ref.read(selectedProductProvider.notifier).state = productData.productName;
                  ref.read(orderIdProvider.notifier).state = orderId;
                  await GoRouter.of(context).push('/ingredient_list');
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IngredientsDoneCheck(orderId: orderId, productName: productData.productName),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productData.productName,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          Text(
                            'to make: ${assignedProduct.amountToProduce} kg',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => const Center(
          child: Text('Error occurred!'),
        ),
      ),
    );
  }
}
