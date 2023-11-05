import 'package:compounders/providers/states/login_controller.dart';
import 'package:compounders/providers/states/login_states.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wear/wear.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginControllerProvider, (previous, state) {
      if (state is LoginStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error),
          ),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/login_screen.jpg',
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          WatchShape(
            builder: (context, shape, child) {
              final isRound = shape == WearShape.round;
              final screenFraction = MediaQuery.of(context).size.width * 0.5;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: screenFraction,
                        height: screenFraction,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(isRound ? screenFraction / 2 : 20.0),
                        ),
                        child: MaterialButton(
                          child: const Text('Sign in with Google', style: TextStyle(color: Colors.black)),
                          onPressed: () {
                            //ref.read(loginControllerProvider.notifier).loginWithGoogle();
                            context.go('mixers');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
