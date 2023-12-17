import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
///This is a class handling all operations related to authentication the users.
class AuthRepository {
  /// Constructs an `AuthRepository` with a given [FirebaseAuth] instance.
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  /// Firebase Firestore instance to interact with Firestore database.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  /// Stream of [User] that notifies about changes to the user's sign-in state (sign-in, sign-out, token refresh).
  /// It provides a continuous stream of the user's authentication state.
  Stream<User?> get authStateChange => _auth.idTokenChanges();

  /// Getter to retrieve the currently signed-in user's email address.
  /// Returns an empty string if the user is not signed in.
  String get userEmailAddress => _auth.currentUser?.email ?? '';

  /// Getter to retrieve the currently signed-in user's unique ID.
  /// Returns an empty string if no user is signed in.
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Signs in a user with an email and password.
  /// Throws an [AuthException] with a message for specific authentication errors.
  ///
  /// Parameters:
  ///   - `email`: The user's email address.
  ///   - `password`: The user's password.
  ///
  /// Returns a [User] upon successful authentication.
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException('User not found');
      } else if (e.code == 'wrong-password') {
        throw AuthException('Wrong password.');
      } else {
        throw AuthException('An error occurred. Please try again later.');
      }
    }
  }

  /// Signs out the currently signed-in user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Instance of [GoogleSignIn] to handle Google sign-in flow.
  final GoogleSignIn _googleSignIn = GoogleSignIn();


  /// Signs in a user with Google authentication.
  /// Upon success, checks if a Firestore document exists for the user.
  /// If not, it creates a new document with initial data.
  ///
  /// Returns [UserCredential] upon successful sign-in.
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final googleUser = await _googleSignIn.signIn();

    // Obtain the auth details from the request
    final googleAuth =
    await googleUser!.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    final userCredential =
    await _auth.signInWithCredential(credential);

    // Checking if user data already exists
    final usersRef = _firestore.collection('users');
    final snapshot = await usersRef.doc(userCredential.user!.uid).get();

    if (!snapshot.exists) {
      // If the user data does not exist, create a new document
      await usersRef.doc(userCredential.user!.uid).set({
        'workingHours': 7, // Replace with actual working hours
        'avatarUrl': userCredential.user!.photoURL,
        // add more fields as needed
      });
    }

    return userCredential;
  }
}

/// A custom exception class for authentication-related errors.
/// Contains a message that describes the authentication error.
class AuthException implements Exception {

  /// Constructs an [AuthException] with an error [message].
  AuthException(this.message);
  /// A message coming from Exception.
  final String message;

  @override
  String toString() => message;
}
