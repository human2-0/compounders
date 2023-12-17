import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/product_model.dart';
import 'package:hive/hive.dart';

///ProductsRepository serves as a data access layer for product-related operations within an application.
///It facilitates the retrieval of product details from both a local Hive store and a Firestore database,
///ensuring efficient access to product information and reducing network calls by caching data locally.
class ProductsRepository {
  ///Initializes a new ProductsRepository instance with the required dependencies for data operations related to product details.
  ///
  /// Parameters:
  /// _firestore: An instance of FirebaseFirestore which is used to perform operations on the Firestore database. It is expected to be passed in already initialized and ready to interact with the database.
  /// _productDetailsBox: A Hive box instance of type ProductDetails that serves as a local cache for product details. It allows the application to access product information offline and enhances performance by reducing the need for network calls.
  ProductsRepository(this._firestore, this._productDetailsBox);
  final FirebaseFirestore _firestore;
  final Box<ProductDetails> _productDetailsBox;

  ///Retrieves the details of a product based on mixer ID, product ID, and order ID. It employs a two-tier caching strategy;
  ///it first attempts to fetch the product details from the local Hive store and, if not found, it then fetches from the Firestore database.
  ///The fetched details are subsequently cached in Hive for future offline access.
  Future<ProductDetails> getProductDetails(String mixerId, String productId, String orderId) async {
    // Form a unique key using mixerId and orderId
    final uniqueKey = '$mixerId-$productId-$orderId';

    // First, try to get the product details from the Hive box
    final cachedProductDetails = _productDetailsBox.get(uniqueKey);
    if (cachedProductDetails != null) {
      return cachedProductDetails;
    } else {
      // If not in the box, fetch from Firestore
      final DocumentSnapshot productDocument = await _firestore
          .collection('products')
          .doc(productId)
          .get(); // Assuming the document id in Firestore is still the orderId

      if (productDocument.exists) {
        final productDetails = ProductDetails.fromJson(productDocument.data()! as Map<String, dynamic>);

        // Save to Hive for future use
        await _productDetailsBox.put(uniqueKey, productDetails);

        return productDetails;
      } else {
        throw Exception('Product not found');
      }
    }
  }
}
