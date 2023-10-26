import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/mixers_models.dart';
import '../repository/mixers_repository.dart';

final dateProvider = StateProvider<DateTime>((ref) {
  // Return today's date as an example.
  // You could also fetch or calculate the desired date based on your requirements.
  return DateTime.now();
});

final mixersRepositoryProvider = Provider<MixersRepository>((ref) {
  return MixersRepository(FirebaseFirestore.instance, Hive.box<Mixer>('mixerBox'));
});


final mixerStreamProvider = StreamProvider<List<Mixer>>((ref) {
  final repository = ref.watch(mixersRepositoryProvider);
  final date = ref.watch(dateProvider); // Fetch the date from the dateProvider

  return repository.streamMixers(date);
});

