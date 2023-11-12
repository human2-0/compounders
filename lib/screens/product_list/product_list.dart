import 'package:compounders/providers/mixers_provider.dart';
import 'package:compounders/providers/products_provider.dart';
import 'package:compounders/screens/product_list/ingredients_done_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `ProductListScreen` presents a list of products associated with the selected mixer.
///
/// It retrieves the current product list and mixer name from the application's state using
/// Riverpod's state management. The list is displayed in a `ListView.builder`, with each item
/// being tappable and leading to a detailed ingredient list for the selected product.
///
/// The screen uses a black-themed `Scaffold` with an `AppBar` displaying the mixer's name.
/// The body of the scaffold updates based on the state of the product list: it shows a loading
/// indicator while fetching data, and each product has an icon indicator if the product is ready to issue 'mix sheet'.
///
/// Parameters:
///   - `key`: A [Key] used to uniquely identify the widget in the widget tree.
class ProductListScreen extends ConsumerWidget {
  /// Constructs a `ProductListScreen` widget.
  const ProductListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              return GestureDetector(
                onTap: () async {
                  ref.read(selectedProductProvider.notifier).state = productDisplayData.productDetails.productName;
                  ref.read(orderIdProvider.notifier).state = productDisplayData.queryData.orderId;
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
                      IngredientsDoneCheck(
                          orderId:  productDisplayData.queryData.orderId,
                          productName: productDisplayData.productDetails.productName
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productDisplayData.productDetails.productName,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          Text(
                            'to make: ${productDisplayData.product.amountToProduce} kg',
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
