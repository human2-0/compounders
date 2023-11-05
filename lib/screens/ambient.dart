import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear/wear.dart';

class AmbientScreen extends ConsumerWidget {
  const AmbientScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) => WatchShape(
        builder: (context, shape, child) => const Text('Ambient Screen', style: TextStyle(fontSize: 7),)
    );
}
