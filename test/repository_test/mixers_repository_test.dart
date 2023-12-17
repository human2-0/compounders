import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compounders/models/mixers_model.dart';
import 'package:compounders/repository/mixers_repository.dart';
import 'package:compounders/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'mixers_repository_test.mocks.dart';

@GenerateNiceMocks([
  // Specify the generic types explicitly
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(as: #MockCollectionReference),
  MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentReference),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockQuerySnapshot),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(as: #MockQueryDocumentSnapshot),
  // ... other mocks
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollectionRef;
  late MockDocumentReference mockDocRef;
  late MockQuerySnapshot mockQuerySnapshot;
  late MixersRepository mixersRepository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollectionRef = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockQuerySnapshot = MockQuerySnapshot();
    mixersRepository = MixersRepository(mockFirestore);

    // Stub the Firestore interactions
    when(mockFirestore.collection('mixers')).thenReturn(mockCollectionRef);
    when(mockCollectionRef.doc(any)).thenReturn(mockDocRef);
    when(mockDocRef.collection('orders')).thenReturn(mockCollectionRef);
    when(mockCollectionRef.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));
  });


  test('streamMixers emits a list of Mixers for a given date', () async {
    // Prepare the data to be returned by Firestore
    final mixerData = {
      'mixerId': 'mixer123',
      'lastUpdated': DateTime(2023),
      'mixerName': '400 kg',
      'shift': 'day',
      'assignedProducts': {
        'unique_order_id_11234425435235': {'productId': 'HQV3fkM0H2C9p4DVrfGI', 'amountToProduce': 800}
      }
    };
    final mockQueryDocSnapshot = MockQueryDocumentSnapshot();
    when(mockQueryDocSnapshot.data()).thenReturn(mixerData);
    when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);

    // Call the streamMixers method
    final testDate = DateTime(2023);
    final stream = mixersRepository.streamMixers(testDate);

    // Collect the emitted values
    final result = await stream.first;

    // Verify the result
    expect(result.length, 1);
    expect(result.first, isA<Mixer>());
    expect(result.first.mixerId, 'mixer123');
    // ... other assertions as needed
  });

  test('streamMixers emits an empty list when no mixers are found', () async {
    // Simulate Firestore returning an empty list
    when(mockQuerySnapshot.docs).thenReturn([]);

    // Call the streamMixers method
    final testDate = DateTime(2023);
    final stream = mixersRepository.streamMixers(testDate);

    // Collect the emitted values
    final result = await stream.first;

    // Verify that an empty list is emitted
    expect(result, isEmpty);
  });

  group('streamMixers Error Handling', ()
  {
    test('Emits MixerNetworkException on network error', () {
      // Simulate network error
      when(mockCollectionRef.snapshots()).thenAnswer((_) => Stream.error(FirestoreException('UNAVAILABLE')));

      expect(
          mixersRepository.streamMixers(DateTime.now()),
          emitsError(isA<MixerNetworkException>())
      );
    });

    test('Emits MixerFormatException on format error', () {
      // Simulate format exception
      when(mockCollectionRef.snapshots()).thenAnswer((_) => Stream.error(const FormatException()));

      expect(
          mixersRepository.streamMixers(DateTime.now()),
          emitsError(isA<MixerFormatException>())
      );
    });

    test('Emits MixerStreamException on unexpected error', () {
      // Simulate unexpected error
      when(mockCollectionRef.snapshots()).thenAnswer((_) => Stream.error(Exception('Unexpected error')));

      expect(
          mixersRepository.streamMixers(DateTime.now()),
          emitsError(isA<MixerStreamException>())
      );
    });
  });




  // Additional tests...
}
