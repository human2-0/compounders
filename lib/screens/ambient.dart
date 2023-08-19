import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear/wear.dart';

class AmbientScreen extends ConsumerWidget {

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WatchShape(
        builder: (BuildContext context, WearShape shape, Widget? child) {
          return Container(child: Text('Ambient Screen'));
        }
    );
  }
}