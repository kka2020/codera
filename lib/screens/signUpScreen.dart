import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'homeScreen.dart';

class SignUpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return RegisterScreen(
            providers: [
              EmailAuthProvider(),
            ],
            // Use headerBuilder to add a username field at the top of the form.
            headerBuilder: (context, constraints, _) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  key: const ValueKey('username'),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                  onSaved: (value) async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && value != null && value.isNotEmpty) {
                      await user.updateDisplayName(value);
                    }
                  },
                ),
              );
            },
          );
        }
        return HomeScreen();
      },
    );
  }
}
