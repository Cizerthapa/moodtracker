import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/features/auth/data/repositories/user_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';


class AuthRepository {
  AuthRepository();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    log('FirebaseAuth: Signing in with email $email', name: 'Firebase');
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    log('FirebaseAuth: Signed in successfully for ${credential.user?.uid}', name: 'Firebase');
    return credential;
  }

  Future<UserCredential> signUp(String email, String password) async {
    log('FirebaseAuth: Signing up with email $email', name: 'Firebase');
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    log('FirebaseAuth: Signed up successfully for ${credential.user?.uid}', name: 'Firebase');
    if (credential.user != null) {
      await sl<UserRepository>().createUserProfile(credential.user!);
    }
    return credential;
  }

  Future<void> signOut() async {
    log('FirebaseAuth: Signing out user ${_auth.currentUser?.uid}', name: 'Firebase');
    await _auth.signOut();
    log('FirebaseAuth: Signed out successfully', name: 'Firebase');
  }
  Future<void> sendPasswordResetEmail(String email) async {
    log('FirebaseAuth: Sending password reset email to $email', name: 'Firebase');
    await _auth.sendPasswordResetEmail(email: email);
    log('FirebaseAuth: Password reset email sent successfully', name: 'Firebase');
  }
}
