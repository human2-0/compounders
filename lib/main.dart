import 'package:flutter/material.dart';
import 'package:compounders/providers/router_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';
import 'models/ingredient_model.dart';

Future<void> main() async {




  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  Hive.registerAdapter(IngredientStateAdapter());


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: MyApp()));

}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // home: Scaffold(
      //   body: WatchShape(
      //     builder: (BuildContext context, WearShape shape, Widget? child) {
      //       return AmbientMode(
      //         builder: (BuildContext context, WearMode mode, Widget? child) {
      //           return Center(
      //             child: mode == WearMode.active ? LoginScreen() : AmbientScreen(),
      //           );
      //         },
      //       );
      //     },
      //   ),y
      // ),
    );
  }
}
