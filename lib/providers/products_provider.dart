import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/product_model.dart';
import 'package:compounders/providers/mixers_provider.dart';
import 'package:compounders/repository/products_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final productDetailsBox = Hive.box<ProductDetails>('productDetailsBox');
  return ProductsRepository(firestore, productDetailsBox);
});

final productDetailsProvider = FutureProvider.family<ProductDetails, ProductQueryData>((ref, queryData) {
  final productsRepo = ref.read(productsRepositoryProvider);
  return productsRepo.getProductDetails(queryData.mixerName, queryData.productId, queryData.orderId);
});

final consolidatedProductListProvider = FutureProvider<List<ProductDisplayData>>((ref) async {
  final productsRepository = ref.read(productsRepositoryProvider);
  final products = ref.read(assignedProductsInMixerProvider);

  if (products.isEmpty) {
  } else {}

  final productList = <ProductDisplayData>[];

  for (final entry in products.entries) {
    final orderId = entry.key;
    final assignedProduct = entry.value;

    final productDetails =
        await productsRepository.getProductDetails(ref.watch(currentMixerProvider), assignedProduct.productId, orderId);

    productList.add(
      ProductDisplayData(
        product: assignedProduct,
        productDetails: productDetails,
        queryData: ProductQueryData(
          mixerName: ref.watch(currentMixerProvider),
          productId: assignedProduct.productId,
          orderId: orderId,
        ),
      ),
    );
  }

  if (productList.isEmpty) {
  } else {}

  return productList;
});

final selectedProductProvider = StateProvider<String>((ref) => '');
final orderIdProvider = StateProvider<String>((ref) => '');
