import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/features/auth/data/repositories/auth_repository.dart';
import 'package:moodtrack/features/auth/data/repositories/user_repository.dart';
import 'package:moodtrack/features/auth/presentation/pages/login_screen.dart';
import 'package:moodtrack/features/entry/presentation/pages/entry_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthRepository().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in — refresh FCM token + lastSeen in background
          _onUserLoggedIn(snapshot.data!);
          return const EntryScreen();
        }

        // User is not logged in
        return const LoginScreen();
      },
    );
  }

  Future<void> _onUserLoggedIn(User user) async {
    final repo = UserRepository();
    // Fire and forget — don't block the UI
    repo.updateLastSeen();
    repo.refreshFcmToken(user.uid);
  }
}
