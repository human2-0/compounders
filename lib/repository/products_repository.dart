import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mixers_models.dart';

class ProductsRepository {
  final FirebaseFirestore _firestore;

  ProductsRepository(this._firestore);

  Future<ProductDetails> getProductDetails(String productId) async {
    DocumentSnapshot productDocument = await _firestore.collection('products').doc(productId).get();

    if (productDocument.exists) {
      return ProductDetails.fromJson(productDocument.data() as Map<String, dynamic>);
    } else {
      throw Exception("Product not found");
    }
  }
}

final productsRepository = Provider<ProductsRepository>((ref) {
  return ProductsRepository(FirebaseFirestore.instance);
});