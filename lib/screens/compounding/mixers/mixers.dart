import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/ingredient_model.dart';
import 'package:compounders/providers/compounding_provider.dart';
import 'package:compounders/providers/mixers_provider.dart';
import 'package:compounders/screens/ambient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:wear/wear.dart';

class MixersScreen extends ConsumerStatefulWidget {
  const MixersScreen({super.key});

  @override
  MixersScreenState createState() => MixersScreenState();
}

class MixersScreenState extends ConsumerState<MixersScreen> {

  Future<void> _fetchInitialData() async {
    // Fetch all ingredients, or a subset based on app logic
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('ingredients').get();

    final box = await Hive.openBox<IngredientState>('ingredientBox');
    for (final doc in querySnapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      // Convert Timestamp to DateTime
      data['lastUpdated'] = (data['lastUpdated'] as Timestamp).toDate();

      final ingredientState = IngredientState.fromMap(data);
      await box.put(doc.id, ingredientState);
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_fetchInitialData());
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
              error: (error, stack) => Center(
                  child: Text(
                'Error: $error',
                style: const TextStyle(fontSize: 6),
              )),
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
