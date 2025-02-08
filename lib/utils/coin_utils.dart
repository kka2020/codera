import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> updateUserCoinBalance(int newBalance) async {
  User? user = FirebaseAuth.instance.currentUser;
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'coinBalance': newBalance}, SetOptions(merge: true));
    }
  });
}

Future<int> getUserCoinBalance(String userId) async {
  try {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final balance = data['coinBalance'] as int?;
      return balance ?? 0;
    }
    return 0;
  } catch (e) {
    return 0;
  }
}