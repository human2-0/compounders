import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/mixers_model.dart';
import 'package:compounders/repository/mixers_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentMixerProvider = StateProvider<String>((ref ) => '');
final assignedProductsInMixerProvider = StateProvider<Map<String,AssignedProduct>>((ref ) => {});

final dateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final mixersRepositoryProvider = Provider<MixersRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider); // Use a provider for Firestore instance
  return MixersRepository(firestore);
});
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) =>
  FirebaseFirestore.instance // Default to real instance
);


final mixerStreamProvider = StreamProvider<List<Mixer>>((ref) {
  final repository = ref.watch(mixersRepositoryProvider);
  final date = ref.watch(dateProvider); // Fetch the date from the dateProvider

  return repository.streamMixers(date);
});
