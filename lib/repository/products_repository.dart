import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';

import 'package:hive/hive.dart';
class ProductsRepository {
  final FirebaseFirestore _firestore;
  final Box<ProductDetails> _productDetailsBox;

  ProductsRepository(this._firestore, this._productDetailsBox);

  Future<ProductDetails> getProductDetails(String productId) async {
    // First, try to get the product details from the Hive box
    var cachedProductDetails = _productDetailsBox.get(productId);

    if (cachedProductDetails != null) {
      return cachedProductDetails;
    } else {
      // If not in the box, fetch from Firestore
      DocumentSnapshot productDocument =
      await _firestore.collection('products').doc(productId).get();

      if (productDocument.exists) {
        ProductDetails productDetails =
        ProductDetails.fromJson(productDocument.data() as Map<String, dynamic>);

        // Save to Hive for future use
        await _productDetailsBox.put(productId, productDetails);

        return productDetails;
      } else {
        throw Exception("Product not found");
      }
    }
  }
}

final productsRepository = Provider<ProductsRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final productDetailsBox = Hive.box<ProductDetails>('productDetailsBox');
  return ProductsRepository(firestore, productDetailsBox);
});
