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

///Initializes the application with necessary configurations and setups for time zones, local storage, Firebase, and data cleanup.
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/London'));

  final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
  Hive
    ..init(appDocumentDirectory.path)
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

  await cleanupOldHiveData();
}

void main() async {
  await initializeApp();
  runApp(const ProviderScope(child: Compounding()));
}

/// Compounding is a widget that builds the main application.
///
/// It extends ConsumerWidget, indicating that it uses the Riverpod package for state management
/// to watch and react to changes. It requires a key which should be passed to the super constructor.
/// Inside, it defines a build method that takes a BuildContext and a WidgetRef for context and
/// state management respectively.
///
/// The build method obtains a router object from the state (watched via the routerProvider)
/// and returns a MaterialApp configured for routing. The MaterialApp.router constructor is used
/// to enable named routing throughout the app.
///
/// The debugShowCheckedModeBanner is set to false to disable the debug banner that appears
/// in the top-right corner of the app when running in debug mode.
///
/// Usage:
/// ```dart
/// void main() {
///   runApp(const ProviderScope(child: MyApp()));
/// }
/// ```
///
class Compounding extends ConsumerWidget {
  /// Creates an immutable widget that listens to changes in the application state.
  ///
  /// The [Compounding] widget extends [ConsumerWidget] and utilizes the Riverpod package
  /// to manage state. It takes an optional [Key] as a parameter to uniquely identify the widget
  /// in the widget tree, which can be useful for preserving state when widgets move around in the tree.
  ///
  /// The `const` keyword indicates that the constructor can create compile-time constants,
  /// improving performance by allowing widgets to be immutable and potentially reducing the need
  /// to rebuild them.
  ///
  /// Parameters:
  ///   - `key`: The widget key, which is passed to the superclass constructor.
  const Compounding({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}


///This function goes through the pouredAmountBox and deletes records that are not from the current date.
///DateFormat('yyyy-MM-dd').format(DateTime.now()): Formats the current date in 'yyyy-MM-dd' format.
///Hive.box<UsedAmountData>('pouredAmountBox'): Accesses the pouredAmountBox Hive box.
///Iterates over the keys in the box, checking the date associated with each record.
///Records that do not match the current date are added to a list of keys to remove.
///Each key in the list of keys to remove is then deleted from the box.
Future<void> cleanupOldHiveData() async {
  final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final box = Hive.box<UsedAmountData>('pouredAmountBox');

  // Explicitly specify the type of elements in the list as String.
  final keysToRemove = <String>[];

  for (final key in box.keys) {
    final dataRaw = box.get(key);
    // Assume dataRaw contains a 'date' field that can be compared to currentDate.
    if (dataRaw is Map) {
      final date = dataRaw!.date; // Access the date from the Map using the key.
      if (date != currentDate) {
        keysToRemove.add(key as String);
      }
    }
  }

  // Remove outdated records
  for (final key in keysToRemove) {
    await box.delete(key);
  }
}
