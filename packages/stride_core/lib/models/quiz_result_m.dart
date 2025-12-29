import 'package:cloud_firestore/cloud_firestore.dart';

class QuizResult {
  final String id;
  final String name;

  /// A map of question IDs to answers
  final Map<String, dynamic> answers;

  /// A map of question IDs to questions
  final Map<String, String> questions;
  final String userId;
  final Timestamp timestamp;

  QuizResult({
    required this.id,
    required this.name,
    required this.answers,
    required this.questions,
    required this.userId,
    required this.timestamp,
  });

  factory QuizResult.fromMap(Map<String, dynamic> data, String id) {
    return QuizResult(
      id: id,
      name: data['name'] ?? '',
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
      questions: Map<String, String>.from(data['questions'] ?? {}),
      userId: data['userId'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'answers': answers,
      'questions': questions,
      'userId': userId,
      'timestamp': timestamp,
    };
  }
}
