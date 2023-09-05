
import 'dart:async';

import 'package:compounders/providers/auth_provider.dart';
import 'package:compounders/providers/states/login_controller.dart';
import 'package:compounders/providers/states/login_states.dart';
import 'package:compounders/screens/mixers.dart';
import 'package:compounders/screens/protect_screen.dart';
import 'package:compounders/screens/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';




final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);

  // Here you are watching the user.
  final user = ref.watch(authStateProvider);
  final userData = ref.watch(authRepositoryProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    routes: router._routes,
    redirect: (context, state) => router._redirect(user, userData),
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<LoginState>(
      loginControllerProvider,
          (_, __) => notifyListeners(),
    );
  }

  List<GoRoute> get _routes =>
      [
        GoRoute(
          name: 'login',
          builder: (context, state) => const LoginScreen(),
          path: '/login',
        ),
        GoRoute(
          name: 'mixers',
          builder: (context, state) => const MixersScreen(),
          path: '/',

        ),
        GoRoute(
          name: 'protect',
          builder: (context, state) => const ProtectScreen(),
          path: '/protect',
        ),
      ];


  FutureOr<String?> _redirect(user, userData) async {
    // The logic remains the same.
  //   if (user == null) {
  //     return '/login';
  //   } else {
  //     final email = userData.userEmailAddress ?? '';
  //     // Add the check for an empty string here
  //     if (email.isEmpty || !email.endsWith('@lush.co.uk')) {
  //       return '/login';
  //     } else {
  //       return '/';
  //     }
  //   }
   }
}