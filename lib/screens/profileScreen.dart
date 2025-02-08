import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_app/screens/authGate.dart';
import 'package:my_flutter_app/screens/mainPage.dart';
import 'loginScreen.dart'; // make sure to import your LoginScreen
import 'homeScreen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading spinner while waiting for auth state.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If no user is signed in, redirect to LoginScreen using MaterialPageRoute.
        if (!snapshot.hasData || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => AuthGate()),
            );
          });
          return Scaffold(
            body: Center(child: Text('Redirecting to login...')),
          );
        }

        // User is signed in
        final user = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text('Profile'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  // Auth state listener will then redirect to LoginScreen.
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile header with avatar and basic info.
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.blueAccent,
                            backgroundImage: user.photoURL != null 
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? Text(
                                    user.displayName != null && user.displayName!.isNotEmpty
                                        ? user.displayName![0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(fontSize: 40, color: Colors.white),
                                  )
                                : null,
                          ),
                          SizedBox(height: 16),
                          Text(
                            user.displayName ?? 'User',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            user.email ?? 'Unavailable',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Profile details in a card with ListTiles.
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.person),
                          title: Text('Name'),
                          subtitle: Text(user.displayName ?? 'User'),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.email),
                          title: Text('Email'),
                          subtitle: Text(user.email ?? 'Unavailable'),
                        ),
                        // Add more ListTiles here for additional profile info.
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Edit profile button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: Icon(Icons.edit),
                    label: Text('Edit Profile'),
                    onPressed: () {
                      // TODO: Implement profile edit functionality.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Profile edit coming soon!')),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainPage()),
                      );
                    },
                    child: Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
