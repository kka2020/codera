import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_app/utils/coin_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AsteroidsGame extends StatefulWidget {
  final int currentBalance;
  final ValueChanged<int> onBalanceChanged;

  const AsteroidsGame({
    required this.currentBalance,
    required this.onBalanceChanged,
    Key? key,
  }) : super(key: key);

  @override
  _AsteroidsGameState createState() => _AsteroidsGameState();
}

class _AsteroidsGameState extends State<AsteroidsGame> {
  List<Asteroid> asteroids = [];
  String userAnswer = '';
  int coinBalance = 0;
  int correctCount = 0; // Tracks correct answers.
  bool gameOver = false;
  Random random = Random();
  double screenWidth = 400;
  double screenHeight = 600;
  
  // Track questions that have already been used.
  final Set<String> _usedQuestions = {};
  // Track last concept used.
  String? lastConcept;
  
  // Adaptive difficulty fields using 10 levels.
  int adaptiveStreak = 0;
  final int adaptiveThreshold = 5;
  // Keys represent difficulty levels (1-10)
  Map<int, int> deathDifficultyCount = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
    7: 0,
    8: 0,
    9: 0,
    10: 0,
  };

  // Added TextEditingController and FocusNode for the answer input.
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  // Static fallback questions including a new "concept" field.
  final List<Map<String, String>> questions = [
    {
      "question": "FIFO data structure?",
      "answer": "Queue",
      "concept": "data structures"
    },
    {
      "question": "Binary search complexity?",
      "answer": "O(logn)",
      "concept": "algorithms"
    },
    {
      "question": "Python file extension?",
      "answer": ".py",
      "concept": "programming"
    },
    {
      "question": "Linux kernel OS?",
      "answer": "Linux",
      "concept": "computer systems"
    },
    {
      "question": "Protocol for secure web?",
      "answer": "HTTPS",
      "concept": "networking"
    },
    {
      "question": "Database query language?",
      "answer": "SQL",
      "concept": "databases"
    },
  ];

  @override
  void initState() {
    super.initState();
    coinBalance = widget.currentBalance;
    spawnAsteroid();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  // Helper: returns the difficulty level at which the player dies most often.
  int getMostFrequentDeathDifficulty() {
    List<int> lastFiveDeaths = deathDifficultyCount.entries
        .where((entry) => entry.value > 0)
        .toList()
        .reversed
        .take(5)
        .map((entry) => entry.key)
        .toList();

    if (lastFiveDeaths.isEmpty) return 10;

    Map<int, int> lastFiveDeathCounts = {for (var key in lastFiveDeaths) key: deathDifficultyCount[key]!};

    int most = lastFiveDeathCounts.keys.first;
    int mostCount = lastFiveDeathCounts[most]!;
    lastFiveDeathCounts.forEach((key, value) {
      if (value > mostCount) {
        most = key;
        mostCount = value;
      }
    });
    return most;
  }

  // Use OpenAI's API to generate asteroid data with increasing difficulty.
  Future<Asteroid> _fetchAsteroidFromOpenAI() async {
    final apiKey = dotenv.env['API_KEY'] ?? ''; // Replace with your API key.
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // Compute requested difficulty: For example, every 2 correct answers increase the level.
    int requestedDifficulty = ((correctCount) ~/ 2) + 1;
    if (requestedDifficulty > 10) requestedDifficulty = 10;
    int difficulty;
    // If adaptive streak is below threshold and there have been some failures, cap the difficulty.
    int totalDeaths = deathDifficultyCount.values.fold(0, (sum, element) => sum + element);
    if (adaptiveStreak < adaptiveThreshold && totalDeaths > 0) {
      int capDifficulty = getMostFrequentDeathDifficulty();
      print("Cap difficulty: $capDifficulty");
      if (requestedDifficulty > capDifficulty) {
        adaptiveStreak++;
        difficulty = capDifficulty;
        correctCount--;
      } else {
        difficulty = requestedDifficulty;
      }
    } else {
      difficulty = requestedDifficulty;
    }

    // Set the speed multiplier based on difficulty. For example, level 1 => 1.0; level 10 => 1.0 + 9*0.2 = 2.8.
    final double speedMultiplier = 1.0 + (difficulty - 1) * 0.2;

    // If there's a previous concept, instruct the API to change topics.
    final previousInstruction = lastConcept != null
        ? "Note: The previous question's topic was \"$lastConcept\". Generate a question on a different topic."
        : "";
    // if (adaptiveStreak < adaptiveThreshold && totalDeaths > 0) {
    //   int capDifficulty = getMostFrequentDeathDifficulty();
    //   print("Cap difficulty: $capDifficulty");
    //   if (requestedDifficulty > capDifficulty) {
    //     adaptiveStreak++;
    //     difficulty = capDifficulty;
    //   } else {
    //     difficulty = requestedDifficulty;
    //   }
    // } else {
    //   difficulty = requestedDifficulty;
    // }
    // Include previously used questions.
    final previousQuestionsList = _usedQuestions.isNotEmpty ? _usedQuestions.join(", ") : "";
    final previousQuestionsInstruction = previousQuestionsList.isNotEmpty
        ? "Previous questions asked: $previousQuestionsList."
        : "";

    final prompt = '''
Generate a valid JSON object for an asteroid in our game. The JSON object must include exactly these fields:
- "question": A strictly computer science-related question with one plausible answer; make it as short as possible, tailored to a level $difficulty challenge, and testing one of the following topics: data structures, algorithms, programming, computer systems, networking, or databases. Avoid general trivia.
- "answer": A concise answer (1 to 3 words); unambiguous and strictly CS-related.
- "speed": A number (float) between 1.0 and 1.5.
- "concept": One of the following exactly: "data structures", "algorithms", "programming", "computer systems", "networking", "databases". It must not be the same as the previous question's concept.
$previousInstruction
$previousQuestionsInstruction
Return only the JSON without any extra text.
''';

    final body = json.encode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {
          "role": "system",
          "content": "You are a helpful assistant that generates strictly computer science-related asteroid questions for a game."
        },
        {"role": "user", "content": prompt}
      ],
      "temperature": 0.7,
      "max_tokens": 150,
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data["choices"][0]["message"]["content"];
      // Parse the returned content as JSON.
      final parsed = json.decode(content);
      print(parsed);
      print("Effective difficulty: $difficulty");
      return Asteroid(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: parsed["question"] ?? "Default CS Question",
        answer: parsed["answer"] ?? "Default Answer",
        concept: parsed["concept"] ?? "programming",
        x: random.nextDouble() * (screenWidth - 150),
        y: 0,
        // Scale speed with speedMultiplier and screen height.
        speed: (parsed["speed"] is num)
            ? ((parsed["speed"] as num).toDouble() * speedMultiplier * (screenHeight / 600))
            : ((2.0 + random.nextDouble() * 3) * speedMultiplier * (screenHeight / 600)),
        spawnTime: DateTime.now(),
      );
    } else {
      throw Exception('Failed to generate asteroid via OpenAI');
    }
  }

  // Generates an asteroid, ensuring unique questions and a different concept than the last.
  void spawnAsteroid({int attempts = 0}) async {
    if (gameOver) return;
    Asteroid asteroid;
    try {
      asteroid = await _fetchAsteroidFromOpenAI();
    } catch (error) {
      int fallbackDifficulty = ((correctCount) ~/ 2) + 1;
      if (fallbackDifficulty > 10) fallbackDifficulty = 10;
      final double fallbackSpeedMultiplier = 1.0 + (fallbackDifficulty - 1) * 0.2;

      var available = questions.where((q) =>
          !_usedQuestions.contains(q['question']) &&
          (lastConcept == null || q['concept'] != lastConcept)).toList();
      if (available.isNotEmpty) {
        var questionData = available[random.nextInt(available.length)];
        asteroid = Asteroid(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          question: questionData["question"]!,
          answer: questionData["answer"]!,
          concept: questionData["concept"]!,
          x: random.nextDouble() * (screenWidth - 150),
          y: 0,
          // Reduced speed range for fallback asteroids.
          speed: (1.0 + random.nextDouble() * 1.5) * fallbackSpeedMultiplier * (screenHeight / 600),
          spawnTime: DateTime.now(),
        );
      } else {
        var questionData = questions[random.nextInt(questions.length)];
        asteroid = Asteroid(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          question: questionData["question"]!,
          answer: questionData["answer"]!,
          concept: questionData["concept"]!,
          x: random.nextDouble() * (screenWidth - 150),
          y: 0,
          // Reduced speed range for fallback asteroids.
          speed: (0.5 + random.nextDouble() * 1.0) * fallbackSpeedMultiplier * (screenHeight / 600),
          spawnTime: DateTime.now(),
        );
      }
    }

    // Ensure uniqueness and a new concept relative to lastConcept.
    if ((_usedQuestions.contains(asteroid.question) ||
         (lastConcept != null && asteroid.concept == lastConcept)) && attempts < 3) {
      spawnAsteroid(attempts: attempts + 1);
      return;
    }
    
    _usedQuestions.add(asteroid.question);
    lastConcept = asteroid.concept;
    setState(() {
      asteroids.add(asteroid);
    });
    moveAsteroid(asteroid);
  }

  void moveAsteroid(Asteroid asteroid) {
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!mounted || gameOver) {
        timer.cancel();
        return;
      }
      if (!asteroids.contains(asteroid)) {
        timer.cancel();
        return;
      }
      setState(() {
        asteroid.y += asteroid.speed;
      });
      if (asteroid.y > screenHeight - 100) {
        timer.cancel();
        if (asteroids.contains(asteroid)) {
          gameOver = true;
          showGameOver(asteroid.answer);
        }
      }
    });
  }

  // When the player answers correctly.
  void checkAnswer() {
    setState(() {
      String userInput = _answerController.text.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final index = asteroids.indexWhere((asteroid) =>
          asteroid.answer.replaceAll(RegExp(r'\s+'), '').toLowerCase() == userInput);
      if (index != -1) {
        coinBalance += 10;
        correctCount++;
        adaptiveStreak++; // Increase adaptive streak.
        widget.onBalanceChanged(coinBalance);
        updateUserCoinBalance(coinBalance);
        asteroids.removeAt(index);
        spawnAsteroid();
      }
      _answerController.clear();
      _answerFocusNode.requestFocus();
    });
  }

  // On game over, record the death at the current difficulty and reset adaptive streak.
  void showGameOver(String missedAnswer) {
    // Compute current effective difficulty.
    int currentDifficulty = ((correctCount) ~/ 2) + 1;
    if (currentDifficulty > 10) currentDifficulty = 10;
    deathDifficultyCount[currentDifficulty] = deathDifficultyCount[currentDifficulty]! + 1;
    adaptiveStreak = 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Game Over!'),
        content: Text('Your final coin balance: $coinBalance\nMissed answer: $missedAnswer'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            child: Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    setState(() {
      gameOver = false;
      correctCount = 0; // Reset difficulty.
      _usedQuestions.clear();
      lastConcept = null;
      asteroids.clear();
      spawnAsteroid();
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Asteroids Game'),
      ),
      body: Stack(
        children: [
          ...asteroids.map((asteroid) => Positioned(
                key: ValueKey(asteroid.id),
                left: asteroid.x,
                top: asteroid.y,
                child: AsteroidWidget(asteroid: asteroid),
              )),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                focusNode: _answerFocusNode,
                controller: _answerController,
                onSubmitted: (_) => checkAnswer(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter Answer...',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: checkAnswer,
                child: Text('Submit Answer'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Asteroid {
  final String id;
  final String question;
  final String answer;
  final String concept;
  double x;
  double y;
  double speed;
  final DateTime spawnTime;

  Asteroid({
    required this.id,
    required this.question,
    required this.answer,
    required this.concept,
    required this.x,
    required this.y,
    required this.speed,
    required this.spawnTime,
  });
}

class AsteroidWidget extends StatelessWidget {
  final Asteroid asteroid;

  const AsteroidWidget({Key? key, required this.asteroid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate a dynamic circle size based on the screen width.
    final screenWidth = MediaQuery.of(context).size.width;
    // Set circle size to 30% of screen width, clamped between 100 and 250.
    final double circleSize = (screenWidth * 0.2).clamp(100.0, 250.0);
    // Set font size to be proportional to the circle size.
    final double fontSize = circleSize / 12;

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(circleSize * 0.05),
        child: Text(
          asteroid.question,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
