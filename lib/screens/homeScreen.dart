import 'package:flutter/material.dart';
import 'profileScreen.dart';
import 'leaderboardScreen.dart';
import 'settingsScreen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // A little vertical spacing from the top
        SizedBox(height: 70),
        
        // Centered purple title "codera"
        Center(
          child: Text(
            'codera.',
            style: TextStyle(
              color: Colors.purple,
              fontSize: 55,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Push rectangles to the bottom
        Spacer(),

        _buildRectangle(
          context,
          title: 'Profile',
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          },
        ),
        _buildRectangle(
          context,
          title: 'Leaderboard',
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LeaderboardScreen()),
            );
          },
        ),

        // Changed "Transactions" to "Settings," now navigates to SettingsScreen
        _buildRectangle(
          context,
          title: 'Settings',
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
        ),

        SizedBox(height: 50),
      ],
    );
  }

  Widget _buildRectangle(
    BuildContext context, {
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
