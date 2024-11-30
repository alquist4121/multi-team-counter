import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  String id;
  String name;
  int lives;
  int maxLives;

  Team(
      {required this.id,
      required this.name,
      required this.lives,
      required this.maxLives});

  // Firestoreからデータを取得するためのファクトリメソッド
  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'],
      lives: data['lives'],
      maxLives: data['maxLives'],
    );
  }

  // Firestoreにデータを保存するためのメソッド
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'lives': lives,
      'maxLives': maxLives,
    };
  }
}
