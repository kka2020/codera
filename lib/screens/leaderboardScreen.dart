import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_app/utils/coin_utils.dart';

class LeaderboardScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _getLeaderboard() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    // Create a list of user data and wait for their coinBalance via getUserCoinBalance.
    List<Map<String, dynamic>> leaderboard = [];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String name = data['displayName'] ?? 'Anonymous';
      int coinBalance = await getUserCoinBalance(doc.id);
      leaderboard.add({
        'name': name,
        'coinBalance': coinBalance,
      });
    }

    // Sort descending by coinBalance.
    leaderboard.sort((a, b) => b['coinBalance'].compareTo(a['coinBalance']));
    return leaderboard;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final leaderboardData = snapshot.data!;
          return ListView.builder(
            itemCount: leaderboardData.length,
            itemBuilder: (context, index) {
              final user = leaderboardData[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(user['name']),
                trailing: Text('${user['coinBalance']} points'),
              );
            },
          );
        },
      ),
    );
  }
}
