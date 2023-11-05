import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/mixers_model.dart';
import 'package:hive/hive.dart';

class MixersRepository {


  MixersRepository(this._firestore, this._mixerBox);
  final FirebaseFirestore _firestore;
  late final Box<Mixer> _mixerBox;


  Future<void> assignProductToMixer(String mixerId, String productId, int amountToProduce) async {
    try {
      // Get reference to the mixer document
      final DocumentReference mixerRef = _firestore.collection('mixers').doc(mixerId);

      // Generate a unique orderId
      final orderId = DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(9999).toString();

      // Build the product map
      final productMap = <String, dynamic>{
        'productId': productId,
        'amountToProduce': amountToProduce
      };

      // Update Firestore
      await mixerRef.update({
        'assignedProducts.$orderId': productMap,  // Using dot notation to set nested fields
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update Hive
      final mixer = _mixerBox.get(mixerId);
      if (mixer != null) {
        final newProduct = AssignedProduct(productId: productId, amountToProduce: amountToProduce);
        final updatedProducts = Map<String, AssignedProduct>.from(mixer.assignedProducts)
          ..[orderId] = newProduct;
        final updatedMixer = Mixer(
            mixerId: mixer.mixerId,
            assignedProducts: updatedProducts,
            lastUpdated: DateTime.now(),
            shift: mixer.shift,
            mixerName: mixer.mixerName
        );
        await _mixerBox.put(mixerId, updatedMixer);
      }
    } on FormatException {
      rethrow;
    }
  }



  Future<Iterable<Mixer>> getAllMixersWithAssignedProducts(DateTime date) async {
    // Convert DateTime to String in YYYY-MM-DD format
    final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final QuerySnapshot mixerSnapshot = await _firestore.collection('mixers')
        .doc(formattedDate)
        .collection('orders')
        .get();

    final mixers = mixerSnapshot.docs.map((doc) {
      if (doc.data() != null) {
        final mixer = Mixer.fromJson({
          'mixerId': doc.id,
          ...doc.data()! as Map<String, dynamic>,
        });
        _mixerBox.put(doc.id, mixer); // Cache in Hive
        return mixer;
      }
      return null; // This will be filtered out later
    }).toList();

    // Filter out potential null values and return as Iterable<Mixer>
    return mixers.where((mixer) => mixer != null).cast<Mixer>();
  }



  Stream<List<Mixer>> streamMixers(DateTime date) {
    // Convert DateTime to String in YYYY-MM-DD format
    final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    return _firestore.collection('mixers').doc(formattedDate).collection('orders').snapshots().map((snapshot) {
      final List<Mixer?> mixers = snapshot.docs.map((doc) {
        final dataMap = Map<String, dynamic>.from(doc.data());
        return Mixer.fromJson(dataMap);
      }).toList();

      // Filter out potential null values and return as List<Mixer>
      return mixers.where((mixer) => mixer != null).cast<Mixer>().toList();
    });
  }
}
