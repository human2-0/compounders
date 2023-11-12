import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ShowConfirmationDialog extends ConsumerWidget {
  const ShowConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.of(context).size.height;
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
        ),
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: AppBar(
            title: Text(
              'Confirmation',
              style: TextStyle(fontSize: 0.04 * height),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, size: 15),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Do you want to start using a new barrel and save the remaining amount as waste?',
                style: TextStyle(fontSize: 0.05 * height),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: Text('Proceed', style: TextStyle(fontSize: 0.03 * height)),
                onPressed: () async {
                  // Call your topUpIngredient method here
                  GoRouter.of(context).go('/new_barrel');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
