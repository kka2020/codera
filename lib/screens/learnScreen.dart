import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:my_flutter_app/utils/coin_utils.dart';

class LearnScreen extends StatefulWidget {
  final int currentBalance;
  final ValueChanged<int> onBalanceChanged;

  LearnScreen({
    required this.currentBalance,
    required this.onBalanceChanged,
  });

  @override
  _LearnScreenState createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late int _balance;

  final PageController _pageController = PageController();
  
  /// Example flashcards. Each has:
  /// - 'title': short topic
  /// - 'content': a few lines, centered on the front
  /// - 'codeSnippet': python code snippet with "____" placeholder
  /// - 'correctAnswer': what user must type to fill the gap
  final List<Map<String, String>> _flashcards = [
    {
      'title': 'Hello Function',
      'content': 'A simple function that prints "Hello, <name>"',
      'codeSnippet': '''
def greet(____):
    print("Hello, " + ____)
''',
      'correctAnswer': 'name',
    },
    {
      'title': 'Add Function',
      'content': 'A function to add two numbers and return the result',
      'codeSnippet': '''
def add(num1, ____):
    return num1 + ____
''',
      'correctAnswer': 'num2',
    },
  ];

  /// We'll store one controller per card, so user can type the missing piece
  late List<TextEditingController> _answerControllers;

  @override
  void initState() {
    super.initState();
    _balance = widget.currentBalance;

    // Initialize a text controller for each card
    _answerControllers = List.generate(_flashcards.length,
      (_) => TextEditingController()
    );
  }

  /// Called when user taps "Check Answer" on the back of a card
  void _checkAnswer(int cardIndex) {
    final userInput = _answerControllers[cardIndex].text.trim();
    final correctAnswer = _flashcards[cardIndex]['correctAnswer']!;
    if (userInput == correctAnswer) {
      setState(() {
        _balance += 10; // or any amount you want to reward
      });
      widget.onBalanceChanged(_balance);
      updateUserCoinBalance(_balance);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Correct! +\$10')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect! The correct answer is "$correctAnswer"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // No local AppBar because MainPage has it
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _pageController,
      itemCount: _flashcards.length,
      itemBuilder: (context, index) {
        return _buildFlashcard(index);
      },
    );
  }

  Widget _buildFlashcard(int index) {
    final card = _flashcards[index];
    final title = card['title']!;
    final content = card['content']!;
    final codeSnippet = card['codeSnippet']!;

    return Container(
      // Make each page fill most of the screen
      padding: EdgeInsets.all(16),
      child: Center(
        child: FlipCard(
          // flipOnTouch: true => automatically flip on tap
          flipOnTouch: true,
          front: _buildFrontSide(title, content),
          back: _buildBackSide(index, codeSnippet),
        ),
      ),
    );
  }

  /// The front side shows centered text with a topic title + short content
  Widget _buildFrontSide(String title, String content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // center content vertically
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                '(Tap to flip)',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The back side shows the Python code snippet with a placeholder,
  /// plus a TextField for the user’s answer and a "Check" button.
  Widget _buildBackSide(int index, String codeSnippet) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  codeSnippet,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _answerControllers[index],
              decoration: InputDecoration(
                labelText: 'Fill in the gap',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _checkAnswer(index),
              child: Text('Check Answer'),
            ),
          ],
        ),
      ),
    );
  }
}
