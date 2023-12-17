import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

///This widget pushes user to the confirmation screen, before proceeding to issue a new values for the ingredient.
class TopUpButton extends ConsumerWidget{

  // ignore: public_member_api_docs
  const TopUpButton({super.key});
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
              icon: const Icon(Icons.add_shopping_cart_outlined),
              color: Colors.white,
              onPressed: () {
               GoRouter.of(context).go('/show_confirmation_dialog');
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
              child:
              const Center(child: Text('Top up', style: TextStyle(color: Colors.white, fontSize: 11))),
            ),
          ],
        ),
      );
}
