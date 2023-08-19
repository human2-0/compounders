
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/repository/mixers_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:wear/wear.dart';
import 'package:compounders/screens/ambient.dart';

import 'product_list.dart';

class MixersScreen extends ConsumerStatefulWidget {
  const MixersScreen({Key? key}) : super(key: key);

  @override
  _MixersScreenState createState() => _MixersScreenState();
}

class _MixersScreenState extends ConsumerState<MixersScreen> {
  String? currentMixer;

  Future<void> fetchInitialData() async {
    // You could fetch all ingredients, or a subset based on app logic
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('ingredients').get();

    final box = await Hive.openBox('ingredientBox');
    for (var doc in querySnapshot.docs) {
      await box.put(doc.id, doc.data());
    }
  }


  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (BuildContext context, WearShape shape, Widget? child) {
        return AmbientMode(
          builder: (BuildContext context, WearMode mode, Widget? child) {
            if (mode == WearMode.active) {
              final mixersAsyncValue = ref.watch(mixerStreamProvider);

              return mixersAsyncValue.when(
                data: (mixers) {
                  if (mixers.isEmpty) {
                    return const Center(child: Text('No mixers found.'));
                  }

                  return Scrollbar(
                    child: GridView.builder(
                      itemCount: mixers.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: MediaQuery.of(context).size.width /
                            (MediaQuery.of(context).size.height),
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final mixer = mixers[index];

                        return GestureDetector(
                          onTap: () {
                            currentMixer = mixer.mixerName;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(
                                  products: mixer.assignedProducts,
                                  mixerName: currentMixer,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    mixer.mixerId,
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
                error: (error, stack) => Center(child: Text('Error: $error')),
              );
            } else {
              // Add your ambient mode UI here.
              // Typically, ambient mode UIs are simplified versions of the main UI.
              return AmbientScreen();
            }
          },
        );
      },
    );
  }
}



