import 'package:flutter/material.dart';
import 'dart:math';
import 'package:my_flutter_app/utils/coin_utils.dart';

class PlayScreen extends StatefulWidget {
  final int currentBalance;
  final ValueChanged<int> onBalanceChanged;

  PlayScreen({
    required this.currentBalance,
    required this.onBalanceChanged,
  });

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  bool _gameStarted = false;     // Has the quiz game started?
  bool _gameOver = false;       // Has the user ended the game (lost, cashed out, or finished all)?
  bool _finishedAll = false;    // Did the user answer ALL questions correctly?

  int _betAmount = 10;          // Set by the user at setup
  int _multiplier = 1;          // Increments each time the user picks the correct tile
  int _currentQuestionIndex = 0; // Which question are we on?

  int _winnings = 0;            // How much the user ended with (0 if lost, >0 if won/cashed out)

  /// Example quiz data. Add more as needed.
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is 2 + 2?',
      'options': ['3', '4', '5', '22'],
      'correctIndex': 1, // "4" is correct
    },
    {
      'question': 'Which planet is known as the Red Planet?',
      'options': ['Earth', 'Mars', 'Jupiter', 'Venus'],
      'correctIndex': 1, // "Mars" is correct
    },
    {
      'question': 'Dart is used for ______ development',
      'options': ['iOS only', 'Android only', 'Cross-platform', 'Web only'],
      'correctIndex': 2, // "Cross-platform"
    },
  ];

  /// We'll use a 3×3 grid => 9 tiles per question.
  /// Exactly one tile is correct; the other 8 are random wrong answers.
  late List<int> _tiles;

  @override
  void initState() {
    super.initState();
    // The board is generated once the user taps "Start Game."
  }

  /// Return to the setup UI so user can pick a new bet
  void _playAgainNewSetup() {
    setState(() {
      _gameStarted = false;
      _gameOver = false;
      _finishedAll = false;
      _betAmount = 10; 
      _multiplier = 1;
      _currentQuestionIndex = 0;
      _winnings = 0;
    });
  }

  /// Called once the user chooses a bet & taps "Start Game"
  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _finishedAll = false;
      _multiplier = 1;
      _currentQuestionIndex = 0;
      _winnings = 0;
    });
    _randomizeBoard(_currentQuestionIndex);
  }

  /// Build a 3×3 array with 1 correct tile & 8 random wrong tiles
  void _randomizeBoard(int questionIndex) {
    final rand = Random();
    final question = _questions[questionIndex];
    final correctIndex = question['correctIndex'] as int;

    // 3×3 => 9 tiles
    List<int> newTiles = List<int>.filled(9, 0);

    // pick a random position for the correct tile
    int correctPos = rand.nextInt(9);
    newTiles[correctPos] = correctIndex;

    // fill the others with random WRONG answers
    for (int i = 0; i < 9; i++) {
      if (i == correctPos) continue;
      int wrong;
      do {
        wrong = rand.nextInt(4); // 0..3
      } while (wrong == correctIndex);
      newTiles[i] = wrong;
    }

    setState(() {
      _tiles = newTiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Decide which screen to show based on game state
    if (!_gameStarted) {
      return _buildSetupUI();
    } 
    if (_gameOver) {
      // If gameOver => show the result screen (win/loss)
      return _buildResultScreen();
    }
    // Otherwise, show the normal game UI (question + 3×3 grid + CashOut)
    return _buildGameUI();
  }

  /// Setup UI where user picks a bet
  Widget _buildSetupUI() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Bet Amount:'),
          SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(border: OutlineInputBorder()),
            onChanged: (value) {
              _betAmount = int.tryParse(value) ?? 10;
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startGame,
            child: Text('Start Game'),
          ),
        ],
      ),
    );
  }

  /// The main game screen: question text at top, 3×3 grid in middle, CashOut button at bottom
  Widget _buildGameUI() {
    final question = _questions[_currentQuestionIndex];
    final questionText = question['question'] as String;
    final options = question['options'] as List<String>;

    return Column(
      children: [
        // Show question text at top
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            questionText,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        // 3×3 grid
        Expanded(
          child: GridView.builder(
            itemCount: 9,
            gridDelegate: 
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemBuilder: (context, index) {
              int tileValue = _tiles[index];
              String tileAnswer = options[tileValue];
              return GestureDetector(
                onTap: () => _handleTileTap(index),
                child: Container(
                  margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey, // hidden while game in progress
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      tileAnswer,
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Cash out button
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _cashOut,
            child: Text('Cash Out'),
          ),
        ),
      ],
    );
  }

  /// The result screen (either a win or a loss)
  /// If _winnings > 0 => green; else => red
  Widget _buildResultScreen() {
    // If user ended with some money, consider that a "win" (green).
    // If user ended with 0, consider that a "loss" (red).
    final bool isWin = _winnings > 0;

    // If user finished all => show a "Congrats" note
    final bool finishedAll = _finishedAll;

    return Container(
      color: isWin ? Colors.green : Colors.red,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              isWin
                  ? (finishedAll
                     ? 'Congratulations!\nYou answered all questions!'
                     : 'You cashed out!')
                  : 'Game Over!\nYou lost your bet!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            // Show how much user ended with
            Text(
              'You ended with $_winnings coins',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            SizedBox(height: 32),
            // Play Again
            ElevatedButton(
              onPressed: _playAgainNewSetup,
              child: Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle tapping a tile in the 3x3 grid
  void _handleTileTap(int index) {
    if (_gameOver) return;

    final question = _questions[_currentQuestionIndex];
    final correctIndex = question['correctIndex'] as int;
    final tileValue = _tiles[index];

    if (tileValue == correctIndex) {
      // Correct => next question, multiplier++
      _multiplier++;
      _currentQuestionIndex++;

      // If we've used all questions => user got them all correct
      if (_currentQuestionIndex >= _questions.length) {
        _finishedAll = true;
        // We'll auto-cash out
        _cashOut(allAnswered: true);
      } else {
        // randomize next question
        _randomizeBoard(_currentQuestionIndex);
      }
    } else {
      // Wrong => user loses bet
      final newBalance = widget.currentBalance - _betAmount;
      widget.onBalanceChanged(newBalance);
      updateUserCoinBalance(newBalance);

      _winnings = 0; // lost
      _gameOver = true;
      setState(() {});
    }
  }

  /// The user can cash out => betAmount * multiplier
  void _cashOut({bool allAnswered = false}) {
    if (!_gameOver) {
      _winnings = _betAmount * _multiplier;
      final newBalance = widget.currentBalance + _winnings;
      widget.onBalanceChanged(newBalance);
      updateUserCoinBalance(newBalance);

      _gameOver = true;
      setState(() {});
    }
  }
}
