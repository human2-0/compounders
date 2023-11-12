import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScaleButton extends ConsumerWidget {
  const ScaleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.scale_rounded),
              color: Colors.white,
              onPressed: () {
                // your functionality goes here
              },
            ),
            Container(
                width: MediaQuery.sizeOf(context).width * 0.25,
                decoration: const BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: const Center(
                    child: Text('Scale', style: TextStyle(color: Colors.white, fontSize: 11)))),
          ],
        ),
      );
  }
