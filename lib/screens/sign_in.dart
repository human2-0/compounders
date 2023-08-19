import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wear/wear.dart';
import '../providers/states/login_states.dart';
import '../providers/states/login_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
            builder: (BuildContext context, WearShape shape, Widget? child) {
              final bool isRound = shape == WearShape.round;
              final double screenFraction = MediaQuery.of(context).size.width * 0.5;

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
