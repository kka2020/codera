import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_app/utils/coin_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  List<Map<String, dynamic>> _flashcards = [];
  bool _isLoading = false;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _balance = widget.currentBalance;
    _fetchFlashcards();
  }

  /// Fetch a batch of flashcards from the RAG engine (OpenAI API)
  /// and append them to the existing list.
  Future<void> _fetchFlashcards() async {
    // Prevent multiple simultaneous fetches.
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch a batch (e.g., 5 flashcards)
      List<Map<String, dynamic>> cards = await _fetchFromRAG(5);
      // Randomize order
      cards.shuffle();
      setState(() {
        _flashcards.addAll(cards);
      });
    } catch (e) {
      print("Error fetching flashcards: $e");
      // Optionally show an error message in the UI.
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Calls the OpenAI ChatCompletion endpoint to generate `count` flashcards.
  /// Each flashcard is expected to be in JSON with the keys:
  /// - "frontTitle": short concept name,
  /// - "frontContent": short explanation (1-3 sentences),
  /// - "backQuestion": a related multiple-choice question,
  /// - "backOptions": array of exactly 4 strings,
  /// - "correctIndex": an integer (0..3).
  Future<List<Map<String, dynamic>>> _fetchFromRAG(int count) async {
    final apiKey = dotenv.env['API_KEY'] ?? ''; // Replace with your actual OpenAI API key
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final prompt = '''
Generate $count random computer science concept flashcards using retrieval-augmented generation.
Each flashcard should be in valid JSON format with the following keys:
- "frontTitle": a short concept name,
- "frontContent": a brief explanation (1-3 sentences),
- "backQuestion": a multiple-choice question related to the concept,
- "backOptions": an array of exactly 4 strings,
- "correctIndex": an integer from 0 to 3 indicating the correct option.
Return only an array of objects in valid JSON format with no extra text.
Example:
[
  {
    "frontTitle": "Big O Notation",
    "frontContent": "Describes the upper bound of algorithm complexity.",
    "backQuestion": "What does Big O measure?",
    "backOptions": ["Memory", "Time", "Space", "Cost"],
    "correctIndex": 1
  },
  ...
]
''';

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content": "You are a helpful tutor. Provide ONLY valid JSON, no extra text."
          },
          {"role": "user", "content": prompt},
        ],
        "temperature": 0.9,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawContent = data["choices"][0]["message"]["content"];
      final List parsed = jsonDecode(rawContent);
      // Convert each item into a Map<String, dynamic>
      return parsed.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to fetch flashcards: ${response.statusCode}");
    }
  }

  /// Checks the answer on a flashcard. If correct, adds 10 coins and slides to the next card.
  void _checkAnswer(int cardIndex, int chosenIndex) {
    final currentCard = _flashcards[cardIndex];
    int correctIndex = currentCard["correctIndex"];
    if (chosenIndex == correctIndex) {
      // Calculate new balance from the parent's balance
      final newBalance = widget.currentBalance + 10;
      // Update parent's balance and Firestore.
      widget.onBalanceChanged(newBalance);
      updateUserCoinBalance(newBalance);
      _showFloatingSnack("Correct! +10 coins");

      // Advance page or fetch more flashcards, etc.
      if (cardIndex < _flashcards.length - 1) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _showFloatingSnack("End of batch. Loading more flashcards...");
        _fetchFlashcards();
      }
    } else {
      _showFloatingSnack("Wrong! Please try again.");
    }
  }

  /// Displays a floating SnackBar higher on the screen.
  void _showFloatingSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 200, left: 16, right: 16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a full-screen loading indicator if flashcards are being loaded for the first time.
    if (_isLoading && _flashcards.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (_flashcards.isEmpty) {
      return Center(child: Text("No flashcards available."));
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _flashcards.length,
          onPageChanged: (index) {
            _currentPageIndex = index;
            // When the user is nearing the end, fetch more flashcards.
            if (index >= _flashcards.length - 3 && !_isLoading) {
              _fetchFlashcards();
            }
          },
          itemBuilder: (context, index) {
            return _buildFlashcard(index);
          },
        ),
        // Display a small loading circle at the bottom when fetching new flashcards.
        if (_isLoading)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildFlashcard(int index) {
    final card = _flashcards[index];
    final frontTitle = card["frontTitle"] ?? "No Title";
    final frontContent = card["frontContent"] ?? "";
    final backQuestion = card["backQuestion"] ?? "";
    final backOptions = card["backOptions"] as List<dynamic>? ?? [];
    return Container(
      padding: EdgeInsets.all(16),
      child: Center(
        child: FlipCard(
          flipOnTouch: true,
          front: _buildFrontSide(frontTitle, frontContent),
          back: _buildBackSide(index, backQuestion, backOptions),
        ),
      ),
    );
  }

  Widget _buildFrontSide(String title, String content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                "(Tap to flip)",
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackSide(int index, String question, List<dynamic> options) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, i) {
                  return ListTile(
                    title: Text(options[i]),
                    leading: Icon(Icons.circle_outlined),
                    onTap: () => _checkAnswer(index, i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
