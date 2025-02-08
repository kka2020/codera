import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_app/screens/profileScreen.dart';
import 'homeScreen.dart';
import 'loginScreen.dart';
import 'usernameScreen.dart';

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loader while waiting for auth state.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If no user is signed in, show the login/register screen.
        if (!snapshot.hasData || snapshot.data == null) {
          // You can choose to show your RegisterScreen or LoginScreen.
          return LoginScreen();
        }

        final user = snapshot.data!;
        // If the user does not have a username (displayName) yet, redirect.
        if (user.displayName == null || user.displayName!.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => UsernameScreen()),
            );
          });
          return Scaffold(
            body: Center(child: Text("Please set your username...")),
          );
        }
        // Otherwise, go to the HomeScreen.
        return ProfileScreen();
      },
    );
  }
}