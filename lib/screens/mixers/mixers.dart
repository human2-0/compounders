import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/providers/ingredients_provider.dart';
import 'package:compounders/providers/mixers_provider.dart';
import 'package:compounders/screens/ambient.dart';
import 'package:compounders/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:wear/wear.dart';

/// `MixersScreen` is a stateful widget that builds the UI for displaying mixers.
///
/// This widget sets up a watch on the application's router and provides a UI
/// that reacts to changes in the mixers' data. The widget uses the Riverpod package
/// for state management, allowing it to listen for updates and rebuild as needed.
///
class MixersScreen extends ConsumerStatefulWidget {
  /// Parameters:
  ///   - `key`: A [Key] which is passed to the super class to uniquely identify the widget
  ///     within the widget tree. It can be useful for preserving the widget state.
  const MixersScreen({super.key});

  @override
  MixersScreenState createState() => MixersScreenState();
}

/// `MixersScreenState` is the state class that manages the state of the `MixersScreen` widget.
///
/// It fetches initial mixer data from a Firestore collection and populates a Hive box with it.
/// The state listens for updates to mixer data and rebuilds its UI when data changes occur.
///
/// The UI includes an AppBar and a GridView to display the mixers. Each mixer is represented
/// as a card, and the user can interact with these cards.
class MixersScreenState extends ConsumerState<MixersScreen> {

  // Future<void> _fetchInitialData(FirebaseFirestore firestore, Box<IngredientState> box) async {
  //   final QuerySnapshot querySnapshot = await firestore.collection('ingredients').get();
  //   for (final doc in querySnapshot.docs) {
  //     final data = doc.data()! as Map<String, dynamic>;
  //     data['lastUpdated'] = (data['lastUpdated'] as Timestamp).toDate();
  //     final ingredientState = IngredientState.fromMap(data);
  //     await box.put(doc.id, ingredientState);
  //   }
  // }

  @override
  void initState() {
    super.initState();
    // final firebaseFirestore = ref.read(firebaseFirestoreProvider);
    // final ingredientBox = ref.read(ingredientBoxProvider);
    // unawaited( _fetchInitialData(firebaseFirestore, ingredientBox));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dateProvider);

    return WatchShape(
      builder: (context, shape, child) => AmbientMode(
        builder: (context, mode, child) {
          if (mode == WearMode.active) {
            final mixersAsyncValue = ref.watch(mixerStreamProvider);

            return mixersAsyncValue.when(
              data: (mixers) {
                if (mixers.isEmpty) {
                  return Scaffold(
                    backgroundColor: Colors.black,
                    body: Column(children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_month_outlined),
                        color: Colors.white,
                        onPressed: () async {
                          await GoRouter.of(context).push('/calendar');
                        },
                      ),
                      const Center(
                          child: Text(
                        'No mixes found.',
                        style: TextStyle(color: Colors.white),
                      )),
                    ]),
                  );
                }

                return Scaffold(
                  backgroundColor: Colors.black,
                  appBar: PreferredSize(
                    preferredSize: const Size.fromHeight(30),
                    child: AppBar(
                        backgroundColor: Colors.black,
                        leading: Row(
                          children: [
                            IconButton(
                              iconSize: 15,
                              icon: const Icon(Icons.settings),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            iconSize: 15,
                            icon: const Icon(Icons.people_alt_outlined),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_month_outlined),
                            iconSize: 15,
                            color: Colors.white,
                            onPressed: () async {
                              await GoRouter.of(context).push('/calendar');
                            },
                          ),
                        ]),
                  ),
                  body: GridView.builder(
                    itemCount: mixers.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: MediaQuery.of(context).size.width / (MediaQuery.of(context).size.height),
                    ),
                    itemBuilder: (context, index) {
                      final mixer = mixers[index];

                      return GestureDetector(
                        onTap: () async {
                          ref.read(currentMixerProvider.notifier).state = mixer.mixerName;
                          ref.read(assignedProductsInMixerProvider.notifier).state = mixer.assignedProducts;
                        await GoRouter.of(context).push('/product_list');
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  mixer.mixerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${mixer.assignedProducts.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      decoration: TextDecoration.none,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                // Check for network-related errors
                var errorMessage = 'Unexpected error.$error';
                if (error is NetworkError || error.toString().contains('UNAVAILABLE')) {
                  errorMessage = 'Network connection lost. Please check your internet connection.';
                }

                if (error is MixerFormatException) {
                  errorMessage = 'Invalid data format.${error.message}';
                }
                return Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16), // Adjusted font size
                        ),
                        ElevatedButton(
                          child: const Text('Retry'),
                          onPressed: () {
                            // Trigger a retry action, e.g., by calling setState or using a state management solution
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            // Add your ambient mode UI here.
            // Typically, ambient mode UIs are simplified versions of the main UI.
            return const AmbientScreen();
          }
        },
      ),
    );
  }
}
