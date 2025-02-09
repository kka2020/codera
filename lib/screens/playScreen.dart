import 'package:flutter/material.dart';
import 'mines_game.dart';
import 'asteroids_game.dart';

class PlayScreen extends StatefulWidget {
  final int currentBalance;
  final ValueChanged<int> onBalanceChanged;

  const PlayScreen({
    required this.currentBalance,
    required this.onBalanceChanged,
    Key? key,
  }) : super(key: key);

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose a Game Mode')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to MinesGame
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MinesGame(
                      currentBalance: widget.currentBalance,
                      onBalanceChanged: widget.onBalanceChanged,
                    ),
                  ),
                );
              },
              child: Text('Mines'),
            ),
            SizedBox(height: 20), // Add some spacing between buttons
            ElevatedButton(
              onPressed: () {
                // Navigate to AsteroidsGame
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AsteroidsGame(
                      currentBalance: widget.currentBalance,
                      onBalanceChanged: widget.onBalanceChanged,
                    ),
                  ),
                );
              },
              child: Text('Asteroids'),
            ),
          ],
        ),
      ),
    );
  }
}