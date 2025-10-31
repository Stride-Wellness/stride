import 'package:cloud_firestore/cloud_firestore.dart';

class QuizResult {
  final String id;
  final String name;
  final Map<String, dynamic> answers;
  final String userId;
  final Timestamp timestamp;

  QuizResult({
    required this.id,
    required this.name,
    required this.answers,
    required this.userId,
    required this.timestamp,
  });

  factory QuizResult.fromMap(Map<String, dynamic> data, String id) {
    return QuizResult(
      id: id,
      name: data['name'] ?? '',
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
      userId: data['userId'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'answers': answers,
      'userId': userId,
      'timestamp': timestamp,
    };
  }
}
