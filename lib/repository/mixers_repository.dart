import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/mixers_model.dart';
import 'package:compounders/utils.dart';


///MixersRepository is responsible for managing the data associated with mixers in a production environment.
///It handles the the retrieval of mixer data, and real-time updates of mixer status.
///It leverages cloud-based Firestore for global persistence and synchronization.
class MixersRepository {
  /// Constructor for creating a MixersRepository.
  /// This repository is responsible for managing mixer-related data in Firestore.
  ///
  /// Parameters:
  ///   - `_firestore`: An instance of FirebaseFirestore for interacting with Firestore.
  MixersRepository(this._firestore);
  final FirebaseFirestore _firestore;

  ///Provides a stream of mixer data for a given date.
  ///This allows for real-time monitoring and updates of mixers' statuses and assigned products as they are updated in Firestore.
  Stream<List<Mixer>> streamMixers(DateTime date) {
    final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return _firestore
        .collection('mixers')
        .doc(formattedDate)
        .collection('orders')
        .snapshots()
        .handleError((error) {
      if (error is FirestoreException && error.code == 'UNAVAILABLE') {
        throw MixerNetworkException('Network connection lost. Please check your internet connection.');
      } else if (error is FormatException) {
        throw MixerFormatException('Invalid data format.');
      } else {
        throw MixerStreamException('Unexpected error: $error');
      }
    })
        .map((snapshot) => snapshot.docs
        .map((doc) => Mixer.fromJson(doc.data()))
        .toList());
  }


}
