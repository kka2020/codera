import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'package:my_flutter_app/utils/coin_utils.dart';

class MinesGame extends StatefulWidget {
  final int currentBalance;
  final ValueChanged<int> onBalanceChanged;

  const MinesGame({
    required this.currentBalance,
    required this.onBalanceChanged,
    Key? key,
  }) : super(key: key);

  @override
  _MinesGameState createState() => _MinesGameState();
}

class _MinesGameState extends State<MinesGame> {
  bool _gameStarted = false;
  bool _gameOver = false;
  bool _finishedAll = false;
  bool _isAnswering = false;
  bool _isLoading = false; // Add a loading state

  int _betAmount = 10;
  int _multiplier = 1;
  int _winnings = 0;
  late int _currentBalance;
  late List<String> _tiles;

  List<Map<String, dynamic>> _questions = [];
  final String _openAIKey = dotenv.env['API_KEY'] ?? ''; // Replace with your OpenAI API key

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.currentBalance;
    _tiles = List.filled(9, '');
  }

  @override
  void didUpdateWidget(MinesGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBalance != oldWidget.currentBalance) {
      setState(() {
        _currentBalance = widget.currentBalance;
      });
    }
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    const String model = "gpt-3.5-turbo"; // Use the correct model
    const String prompt = """
Generate 9 computer science questions with 4 options each and indicate the correct answer.
Format each question as follows:
1. [Question]
Options: A) [Option 1], B) [Option 2], C) [Option 3], D) [Option 4]
Correct Answer: [Correct Option Letter]
""";

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'), // Correct endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 500, // Increase max_tokens to accommodate 9 questions
          'temperature': 0.7,
        }),
      );

      print('API Response: ${response.body}'); // Debug: Print the API response

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String generatedText = data['choices'][0]['message']['content'];

        // Parse the generated text into questions and answers
        _questions = _parseGeneratedText(generatedText);

        // Ensure we have exactly 9 questions
        if (_questions.length < 9) {
          throw Exception('Not enough questions generated. Expected 9, got ${_questions.length}');
        }
      } else {
        throw Exception('Failed to load questions from OpenAI API. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate questions: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  List<Map<String, dynamic>> _parseGeneratedText(String text) {
    final List<Map<String, dynamic>> questions = [];
    final List<String> questionBlocks = text.split('\n\n'); // Split by double newlines

    for (final block in questionBlocks) {
      final List<String> lines = block.split('\n');
      if (lines.length >= 3) {
        final String question = lines[0].replaceAll(RegExp(r'^\d+\.\s*'), ''); // Remove the question number
        final List<String> options = lines[1]
            .replaceAll('Options:', '') // Remove the "Options:" prefix
            .split(',') // Split by commas
            .map((e) => e.trim()) // Remove extra spaces
            .toList();
        final String correctAnswer = lines[2]
            .replaceAll('Correct Answer:', '') // Remove the "Correct Answer:" prefix
            .trim();

        // Ensure there are exactly 4 options
        if (options.length == 4) {
          questions.add({
            'question': question,
            'options': options,
            'correctIndex': options.indexOf(correctAnswer),
          });
        }
      }
    }

    return questions;
  }

  void _playAgain() {
    setState(() {
      _gameStarted = false;
      _gameOver = false;
      _finishedAll = false;
      _betAmount = 10;
      _multiplier = 0;
      _winnings = 0;
      _tiles = List.filled(9, '');
      // _currentBalance = widget.currentBalance;
    });
  }

  void _startGame() async {
    await _generateQuestions(); // Wait for questions to be generated
    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _finishedAll = false;
      _multiplier = 0;
      _winnings = 0;
      _tiles = List.filled(9, '');
    });
  }

  void _handleTileTap(int index) {
    if (_gameOver || _tiles[index].isNotEmpty || _isAnswering) return;

    setState(() {
      _isAnswering = true;
    });

    final question = _questions[index]; // Use the tile index to fetch the corresponding question
    final correctIndex = question['correctIndex'] as int;
    final options = question['options'] as List<String>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(question['question']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(options.length, (i) {
            return ListTile(
              title: Text(options[i]),
              onTap: () {
                Navigator.pop(context);
                _checkAnswer(index, i == correctIndex);
              },
            );
          }),
        ),
      ),
    );
  }

void _checkAnswer(int index, bool isCorrect) {
  setState(() {
    _isAnswering = false;
    if (isCorrect) {
      _tiles[index] = 'gem';
      _multiplier++;
    } else {
      _tiles[index] = 'bomb';
      _currentBalance -= _betAmount;

      // Prevent negative balance
      if (_currentBalance < 0) _currentBalance = 0;

      // Notify parent of balance change
      widget.onBalanceChanged(_currentBalance);
      updateUserCoinBalance(_currentBalance);
      _gameOver = true;
    }

    // Check if all tiles are revealed
    if (!_tiles.contains('')) {
      _finishedAll = true;
      _cashOut();
    }
  });
}

  void _cashOut() {
    if (!_gameOver) {
      setState(() {
        _winnings = _betAmount * _multiplier;
        _currentBalance += _winnings;

        // Notify parent of balance change
        widget.onBalanceChanged(_currentBalance);
        updateUserCoinBalance(_currentBalance);

        _gameOver = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mines Game'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_gameStarted) return _buildSetupUI();
    if (_gameOver) return _buildResultScreen();
    return _buildGameUI();
  }

  Widget _buildSetupUI() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Risk Amount:'),
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

  Widget _buildGameUI() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Balance: $_currentBalance Coins\nMultiplier: x$_multiplier',
            style: TextStyle(fontSize: 18),
          ),
        ),
        Expanded(
          child: GridView.builder(
            itemCount: 9,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _handleTileTap(index),
                child: AnimatedOpacity(
                  opacity: _tiles[index].isEmpty ? 0.2 : 1.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.purple[700],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _tiles[index] == 'gem'
                          ? Icon(Icons.diamond,
                              color: Colors.purple[300], size: 50)
                          : _tiles[index] == 'bomb'
                              ? Icon(Icons.dangerous, color: Colors.red, size: 40)
                              : Container(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(onPressed: _cashOut, child: Text('Cash Out')),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    return Container(
      color: _winnings > 0 ? Colors.green : Colors.red,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _winnings > 0 ? 'You cashed out!' : 'Game Over!',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            Text(
              _winnings > 0
                  ? 'You won $_winnings coins'
                  : 'You lost $_betAmount coins',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            ElevatedButton(
              onPressed: _playAgain,
              child: Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
