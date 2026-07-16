

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../chat/presentation/chat_screen.dart';
import '../../chat/services/chat_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // TODO: Restore conversations/messages from Firestore into SQLite.
          // This will be implemented in the next step once the sync service is complete.
          ChatService();

          return const ChatScreen();
        }

        return const LoginScreen();
      },
    );
  }
}