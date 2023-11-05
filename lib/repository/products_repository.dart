import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/product_model.dart';
import 'package:hive/hive.dart';
class ProductsRepository {

  ProductsRepository(this._firestore, this._productDetailsBox);
  final FirebaseFirestore _firestore;
  final Box<ProductDetails> _productDetailsBox;

  Future<ProductDetails> getProductDetails(String mixerId, String productId, String orderId) async {
    // Form a unique key using mixerId and orderId
    final uniqueKey = '$mixerId-$productId-$orderId';

    // First, try to get the product details from the Hive box
    final cachedProductDetails = _productDetailsBox.get(uniqueKey);
    if (cachedProductDetails != null) {
      return cachedProductDetails;
    } else {
      // If not in the box, fetch from Firestore
      final DocumentSnapshot productDocument =
      await _firestore.collection('products').doc(productId).get(); // Assuming the document id in Firestore is still the orderId

      if (productDocument.exists) {
        final productDetails =
        ProductDetails.fromJson(productDocument.data()! as Map<String, dynamic>);

        // Save to Hive for future use
        await _productDetailsBox.put(uniqueKey, productDetails);

        return productDetails;
      } else {
        throw Exception('Product not found');
      }
    }
  }
}
