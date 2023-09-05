import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';

import '../models/mixers_models.dart';
import '../models/product_model.dart';

class MixersRepository {
  final FirebaseFirestore _firestore;
  late final Box<Mixer> _mixerBox;
  late final Box _metaBox;


  MixersRepository(this._firestore, this._mixerBox) {
    _initMetaBox();
  }

  Future<void> _initMetaBox() async {
    _metaBox = await Hive.openBox('metadata');
  }


  Future<void> assignProductToMixer(String mixerId, String productId,
      int amountToProduce) async {
    try {
      // Get reference to the mixer document
      DocumentReference mixerRef = _firestore.collection('mixers').doc(mixerId);

      // Build the product map
      Map<String, dynamic> productMap = {
        'productId': productId,
        'amountToProduce': amountToProduce
      };

      // Update Firestore
      await mixerRef.update({
        'assignedProducts': FieldValue.arrayUnion([productMap]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update Hive
      final mixer = _mixerBox.get(mixerId);
      if (mixer != null) {
        final newProduct = Product(
            productId: productId, amountToProduce: amountToProduce);
        final updatedProducts = List<Product>.from(mixer.assignedProducts)
          ..add(newProduct);
        final updatedMixer = Mixer(
            mixerId: mixer.mixerId,
            assignedProducts: updatedProducts,
            lastUpdated: DateTime.now(),
            shift: mixer.shift,
            capacity: mixer.capacity,
            mixerName: mixer.mixerName
        );
        _mixerBox.put(mixerId, updatedMixer);
      }
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<Iterable<Mixer?>> getAllMixersWithAssignedProducts() async {
    if (!_mixerBox.isOpen) {
      await Hive.openBox<Mixer>('mixerBox');
    }

    DateTime? lastSynced = _metaBox.get('lastUpdated') as DateTime?;
    lastSynced ??= DateTime.fromMillisecondsSinceEpoch(0);

    // Fetch mixers updated after the last sync
    QuerySnapshot mixerSnapshot = await _firestore.collection('mixers')
        .where('lastUpdated', isGreaterThan: lastSynced)
        .get();

    final mixers = mixerSnapshot.docs.map((doc) {
      if (doc.data() != null) {
        final mixer = Mixer.fromJson({
          'mixerId': doc.id,
          ...doc.data()! as Map<String, dynamic>,
        });
        _mixerBox.put(doc.id, mixer); // Cache in Hive
        return mixer;
      } else {
        return null;
      }
    }).toList();

    // Save the latest sync timestamp to Hive
    _metaBox.put('lastUpdated', DateTime.now());

    return mixers.where((mixer) => mixer != null).cast<
        Mixer>(); // Filter out null values
  }

  Stream<List<Mixer>> streamMixers() {
    return _firestore.collection('mixers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final dataMap = Map<String, dynamic>.from(doc.data());
        final mixer = Mixer.fromJson(dataMap);
        try {
          final mixer = Mixer.fromJson(doc.data());
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
  return MixersRepository(FirebaseFirestore.instance, Hive.box<Mixer>('mixerBox'));
});


final mixerStreamProvider = StreamProvider<List<Mixer>>((ref) {
  final repository = ref.watch(mixersRepositoryProvider);

  return repository.streamMixers();
});