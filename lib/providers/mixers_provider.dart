import 'package:compounders/models/mixers_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentMixerProvider = StateProvider<String>((ref ) => '');
final assignedProductsInMixerProvider = StateProvider<Map<String,AssignedProduct>>((ref ) => {});
