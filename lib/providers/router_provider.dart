
import 'dart:async';

import 'package:compounders/providers/auth_provider.dart';
import 'package:compounders/providers/states/login_controller.dart';
import 'package:compounders/providers/states/login_states.dart';
import 'package:compounders/screens/compounding/compounding.dart';
import 'package:compounders/screens/compounding/confirmation_dialog.dart';
import 'package:compounders/screens/compounding/issue_new_barrel_weights.dart';
import 'package:compounders/screens/compounding/use_whole_barrel.dart';
import 'package:compounders/screens/ingredient_list/ingredient_list.dart';
import 'package:compounders/screens/mixers/calendar_selector.dart';
import 'package:compounders/screens/mixers/mixers.dart';
import 'package:compounders/screens/product_list/product_list.dart';
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

  RouterNotifier(this._ref) {
    _ref.listen<LoginState>(
      loginControllerProvider,
          (_, __) => notifyListeners(),
    );
  }
  final Ref _ref;

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
        GoRoute(
          name: 'calendar',
          builder: (context, state) => const CalendarSelector(),
          path: '/calendar',
        ),
        GoRoute(
          name: 'product_list',
          builder: (context, state) => const ProductListScreen(),
          path: '/product_list',
        ),
        GoRoute(
          name: 'ingredient_list',
          builder: (context, state) => const IngredientListScreen(),
          path: '/ingredient_list',
        ),
        GoRoute(
          name: 'pouring',
          builder: (context, state) => const CompoundingScreen(),
          path: '/pouring',
        ),
        GoRoute(
          name: 'use_whole_barrel',
          builder: (context, state) => const UseWholeBarrel(),
          path: '/use_whole_barrel',
        ),
        GoRoute(
          name: 'new_barrel',
          builder: (context, state) => const IssueNewBarrelWeights(),
          path: '/new_barrel',
        ),
        GoRoute(
          name: 'show_confirmation_dialog',
          builder: (context, state) => const ShowConfirmationDialog(),
          path: '/show_confirmation_dialog',
        ),
      ];


  FutureOr<String?> _redirect(user, userData) async => null;
  
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
   //}
}
