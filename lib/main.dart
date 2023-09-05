import 'package:flutter/material.dart';
import 'package:compounders/providers/router_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'firebase_options.dart';
import 'models/ingredient_model.dart';
import 'models/mixers_models.dart';
import 'models/product_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> initializeApp() async {


  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/London'));

  final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);

  Hive.registerAdapter(IngredientStateAdapter());
  Hive.registerAdapter(MixerAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(ProductDetailsAdapter());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.openBox<Mixer>('mixerBox');
  await Hive.openBox<ProductDetails>('productDetailsBox');
  await Hive.openBox('metadata');
  await Hive.openBox('pouring_data');
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
