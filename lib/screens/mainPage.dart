import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_app/utils/coin_utils.dart';
import 'homeScreen.dart';
import 'learnScreen.dart';
import 'playScreen.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  /// Current tab: 0=Learn, 1=Home, 2=Play
  int _selectedIndex = 1;

  /// The user's global balance, shown in the top-right of the AppBar
  int _balance = 100;

  final List<String> _tabTitles = ['Learn', 'Home', 'Play'];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // If a user is logged in, fetch their coin balance from Firestore.
      int coinBalance = await getUserCoinBalance(user.uid);
      setState(() {
        _balance = coinBalance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the three main screens using the _balance value.
    final List<Widget> screens = [
      // Learn
      LearnScreen(
        currentBalance: _balance,
        onBalanceChanged: (newBalance) {
          setState(() => _balance = newBalance);
        },
      ),
      // Home
      HomeScreen(),
      // Play
      PlayScreen(
        currentBalance: _balance,
        onBalanceChanged: (newBalance) {
          setState(() => _balance = newBalance);
        },
      ),
    ];

    return Scaffold(
      // One AppBar, always visible.
      appBar: AppBar(
        title: Row(
          children: [
            Text(_tabTitles[_selectedIndex]),
            Spacer(),
            Text('Coins: $_balance'),
          ],
        ),
      ),
      // Use IndexedStack to preserve the state of child screens.
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Play'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
