import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mixers_models.dart';

class MixersRepository {
  final FirebaseFirestore _firestore;

  MixersRepository(this._firestore);

  Future<void> assignProductToMixer(String mixerId, String productId, double amountToProduce) async {
    try {
      // Get reference to the mixer document
      DocumentReference mixerRef = _firestore.collection('mixers').doc(mixerId);

      // Build the product map
      Map<String, dynamic> productMap = {
        'productId': productId,
        'amountToProduce': amountToProduce
      };

      // Update the mixer document
      await mixerRef.update({
        'assignedProducts': FieldValue.arrayUnion([productMap]),
      });
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  Future<List<Mixer>> getAllMixersWithAssignedProducts() async {
    try {
      // Get the mixers collection
      QuerySnapshot mixerSnapshot = await _firestore.collection('mixers').get();

      return mixerSnapshot.docs.map((doc) {
        return Mixer.fromJson({
          'mixerId': doc.id,
          ...doc.data()! as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  Stream<List<Mixer>> streamMixers() {
    return _firestore.collection('mixers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final dataMap = Map<String, dynamic>.from(doc.data());
        final mixer = Mixer.fromJson(dataMap);
        try {
          final mixer = Mixer.fromJson(doc.data() as Map<String, dynamic>);
          print("Parsed mixer: $mixer");
        } catch (e) {
          print("Error parsing mixer: $e");
        }
        return mixer;
      }).toList();
    });
  }


}

final mixersRepositoryProvider = Provider<MixersRepository>((ref) {
  return MixersRepository(FirebaseFirestore.instance);
});

final mixerStreamProvider = StreamProvider<List<Mixer>>((ref) {
  final repository = ref.watch(mixersRepositoryProvider);
  return repository.streamMixers();
});
