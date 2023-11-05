import 'package:compounders/providers/auth_provider.dart';
import 'package:compounders/providers/states/login_states.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginController extends StateNotifier<LoginState> {
  LoginController(this.ref) : super(const LoginStateInitial());

  final Ref ref;

  Future<void> login(String email, String password) async {
    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
        email,
        password,
      );
      state = const LoginStateInitial();
    } on FirebaseAuthException catch (e) {
      state = LoginStateError(e.toString());  // Use e.message to get the actual error message
    }
  }


  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const LoginStateInitial();
  }

  Future<void> loginWithGoogle() async {
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const LoginStateSuccess();
    }on FirebaseAuthException catch (e) {
      state = LoginStateError(e.toString());
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>(LoginController.new);
