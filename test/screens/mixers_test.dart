import 'package:compounders/firebase_options.dart';
import 'package:compounders/providers/mixers_provider.dart';
import 'package:compounders/screens/mixers/mixers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUpAll(() async {
    firestore = FakeFirebaseFirestore(); // Initialize the firestore variable
  });
  testWidgets('MixersScreen should display a widget with "400kg" text', (tester) async {

    // Create a fake Firestore instance
    // Mock your Firestore data here if necessary

    await firestore
        .collection('mixers')
        .doc('2023-10-27')
        .collection('orders')
        .doc('mixer123') // Assuming 'mixer123' is the document ID you want to use
        .set({
      'mixerId': 'mixer123',
      'lastUpdated': DateTime.now(),
      'mixerName': '240kg',
      'shift': 'day',
      'assignedProducts': {
        'unique_order_id_11234425435235': {'productId': 'HQV3fkM0H2C9p4DVrfGI', 'amountToProduce': '240'}
      },
    });

    await firestore.collection('ingredients').add({
      'stock': 100.0,
      'currentBarrel': 50.0,
      'tareWeight': 10.0,
      'lastUpdated': DateTime(2023, 10, 27).millisecondsSinceEpoch, // Ensure proper date format
    });

    ProviderContainer(overrides: [
      firebaseFirestoreProvider.overrideWith((ref) => firestore),
      dateProvider.overrideWith((ref) => DateTime(2023, 10, 27)),
    ]);
    // Build your app with the MixersScreen
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MixersScreen(), // Pass the fake Firestore instance if needed
        ),
      ),
    );

    // Ensure the widget finishes any ongoing animations or tasks
    await tester.pumpAndSettle();
    tester.widgetList(find.byType(Text));

    // Check if the text '400kg' is being displayed
    expect(tester.widgetList(find.byType(Text)), expect);
  });
}
