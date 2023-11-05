import 'package:compounders/firebase_options.dart';
import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/models/mixers_model.dart';
import 'package:compounders/models/product_model.dart';
import 'package:compounders/models/used_amount_model.dart';
import 'package:compounders/providers/router_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> initializeApp() async {


  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/London'));

  final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
  Hive..init(appDocumentDirectory.path)

  ..registerAdapter(IngredientStateAdapter())
  ..registerAdapter(MixerAdapter())
  ..registerAdapter(ProductAdapter())
  ..registerAdapter(ProductDetailsAdapter())
  ..registerAdapter<IngredientData>(IngredientDataAdapter())
  ..registerAdapter(UsedAmountDataAdapter())
  ..registerAdapter(IngredientFormulaAdapter());


  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.openBox<Mixer>('mixerBox');
  await Hive.openBox<ProductDetails>('productDetailsBox');
  await Hive.openBox<UsedAmountData>('pouredAmountBox');
  await Hive.openBox<IngredientState>('ingredientBox');
  await Hive.openBox('metadata');
  await Hive.openBox('pouring_data');

  await cleanupOldHiveData();
}

void main() async {
  await initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final router = ref.watch(routerProvider);

    return MaterialApp.router(

      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

Future<void> cleanupOldHiveData() async {
  final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final box = Hive.box<UsedAmountData>('pouredAmountBox');

  final keysToRemove = [];

  for (final key in box.keys) {
    final dataRaw = box.get(key);
    // Print the raw data

    // Directly access the data
    if (dataRaw is Map) {
      final date = dataRaw?.date;
      if (date != null && date != currentDate) {
        keysToRemove.add(key);
      }
    }
  }

  // Remove outdated records
  for (final key in keysToRemove) {
    await box.delete(key);
  }
}
