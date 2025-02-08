import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    // If dark mode is enabled, we'll use a dark background & AppBar
    final backgroundColor = darkModeEnabled ? Colors.black : Colors.white;
    final appBarColor = darkModeEnabled ? Colors.grey[900] : Theme.of(context).primaryColor;
    final textColor = darkModeEnabled ? Colors.white : Colors.black;

    return Scaffold(
      // Dynamically change background color based on darkMode
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: appBarColor,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              'Dark Mode',
              style: TextStyle(color: textColor),
            ),
            value: darkModeEnabled,
            onChanged: (newValue) {
              setState(() {
                darkModeEnabled = newValue;
              });
            },
            // Adjust the switch's active/inactive track color
            activeTrackColor: Colors.grey,
            activeColor: Colors.white,
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // Here you could save the preference to disk or
                // pass it back to the app's global state, etc.
                Navigator.pop(context); // Go back to Home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appBarColor,
              ),
              child: Text('Save', style: TextStyle(color: textColor)),
            ),
          ),
        ],
      ),
    );
  }
}
