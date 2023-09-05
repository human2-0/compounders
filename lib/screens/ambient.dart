import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear/wear.dart';

class AmbientScreen extends ConsumerWidget {
  const AmbientScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WatchShape(
        builder: (BuildContext context, WearShape shape, Widget? child) {
          return const Text('Ambient Screen', style: TextStyle(fontSize: 7),);
        }
    );
  }
}