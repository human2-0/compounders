import 'dart:async';

import 'package:compounders/models/mixers_model.dart';
import 'package:compounders/providers/mixers_provider.dart'; // Replace with your actual file name
import 'package:compounders/repository/mixers_repository.dart';
import 'package:compounders/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'mixers_provider_test.mocks.dart';


@GenerateMocks([MixersRepository])
void main() {
  group('Mixer Stream Provider Tests', () {
    late MockMixersRepository mockMixersRepository;
    final testDate = DateTime(2023);
    final mixerData = Mixer(
      mixerId: 'mixer123',
      lastUpdated: testDate,
      mixerName: '400 kg',
      shift: 'day',
      assignedProducts: {
        'unique_order_id_11234425435235': AssignedProduct(productId: 'HQV3fkM0H2C9p4DVrfGI', amountToProduce: 800)
      },
    );

    setUp(() {
      mockMixersRepository = MockMixersRepository();
      // Ensure that the mock setup matches the method call in the test
      when(mockMixersRepository.streamMixers(testDate)).thenAnswer((_) => Stream.value([mixerData]));
    });

    test('Stream emits correct data based on date', () async {
      final container = ProviderContainer(overrides: [
        mixersRepositoryProvider.overrideWithValue(mockMixersRepository),
        dateProvider.overrideWith((ref) => testDate),
      ]);

      final completer = Completer<void>();

      container.listen(
        mixerStreamProvider,
        (_, state) {
          state.when(
            data: (mixers) {
              if (!completer.isCompleted) {
                expect(mixers, equals([mixerData]));
                completer.complete();
              }
            },
            loading: () => {},
            error: (e, st) => fail('Stream encountered an error: $e'),
          );
        },
      );

      // Wait for the completer to complete
      await completer.future;
    });

    test('Stream emits error on network failure', () async {
      // Simulate immediate error emission
      when(mockMixersRepository.streamMixers(testDate))
          .thenAnswer((_) => Stream.error(MixerNetworkException('Network connection lost. Please check your internet connection.')));

      ProviderContainer(overrides: [
        mixersRepositoryProvider.overrideWithValue(mockMixersRepository),
        dateProvider.overrideWith((ref) => testDate),
      ])

          .listen<AsyncValue<List<Mixer>>>(
        mixerStreamProvider,
            (_, state) {
          if (state is AsyncError) {
            expect(state.error, isA<MixerNetworkException>());
          }
        },
      );
    });

    test('Stream emits unexpected error', () async {
      // Simulate a FormatException
      when(mockMixersRepository.streamMixers(testDate))
          .thenThrow(MixerStreamException('Unexpected error'));

      ProviderContainer(overrides: [
        mixersRepositoryProvider.overrideWithValue(mockMixersRepository),
        dateProvider.overrideWith((ref) => testDate),
      ])

      .listen<AsyncValue<List<Mixer>>>(
        mixerStreamProvider,
            (_, state) {
          if (state is AsyncError) {
            // Check if the error is of type MixerFormatException
            expect(state.error, isA<MixerStreamException>());
          }
        },
      );
    }, timeout: const Timeout(Duration(minutes: 1))); // Increased timeout

    test('Stream emits format exception error when Firestore data is incorrect', () async {
      // Simulate a FormatException
      when(mockMixersRepository.streamMixers(testDate))
          .thenThrow(const FormatException('Invalid data format.'));

     ProviderContainer(overrides: [
        mixersRepositoryProvider.overrideWithValue(mockMixersRepository),
        dateProvider.overrideWith((ref) => testDate),
      ])

      .listen<AsyncValue<List<Mixer>>>(
        mixerStreamProvider,
            (_, state) {
          if (state is AsyncError) {
            // Check if the error is of type MixerFormatException
            expect(state.error, isA<MixerFormatException>());
          }
        },
      );
    }, timeout: const Timeout(Duration(minutes: 1))); // Increased timeout



  });
}
