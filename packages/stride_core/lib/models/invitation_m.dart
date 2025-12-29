import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_core/models/quiz_result_m.dart';

class InvitationModel {
  final String id;
  final String createdBy;
  final String code;
  final Timestamp createdAt;
  final QuizResult quizResult;

  InvitationModel({
    required this.id,
    required this.quizResult,
    required this.createdBy,
    required this.code,
    required this.createdAt,
  });


  factory InvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return InvitationModel(
      id: id,
      createdBy: map['createdBy'] ?? '',
      code: map['code'] ?? '',
      createdAt: map['createdAt'] ?? '',
      quizResult:
          QuizResult.fromMap(Map<String, dynamic>.from(map['quizResult'] ?? {}), ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdBy': createdBy,
      'code': code,
      'createdAt': createdAt,
      'quizResult': quizResult.toMap(),
    };
  }
}