import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';

import 'package:hive/hive.dart';
class ProductsRepository {
  final FirebaseFirestore _firestore;
  final Box<ProductDetails> _productDetailsBox;

  ProductsRepository(this._firestore, this._productDetailsBox);

  Future<ProductDetails> getProductDetails(String mixerId, String productId, String orderId) async {
    // Form a unique key using mixerId and orderId
    String uniqueKey = '$mixerId-$productId-$orderId';

    // First, try to get the product details from the Hive box
    var cachedProductDetails = _productDetailsBox.get(uniqueKey);

    if (cachedProductDetails != null) {
      return cachedProductDetails;
    } else {
      // If not in the box, fetch from Firestore
      print("Fetching product with productId: $productId");
      DocumentSnapshot productDocument =
      await _firestore.collection('products').doc(productId).get(); // Assuming the document id in Firestore is still the orderId

      if (productDocument.exists) {
        ProductDetails productDetails =
        ProductDetails.fromJson(productDocument.data() as Map<String, dynamic>);

        // Save to Hive for future use
        await _productDetailsBox.put(uniqueKey, productDetails);

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

