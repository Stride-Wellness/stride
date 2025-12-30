import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_core/models/quiz_result_m.dart';

class InvitationModel {
  final String id;
  final String createdBy;
  final String divisionId;
  final String organizationId;
  final String code;
  final Timestamp createdAt;
  final QuizResult quizResult;

  InvitationModel({
    required this.id,
    required this.divisionId,
    required this.organizationId,
    required this.quizResult,
    required this.createdBy,
    required this.code,
    required this.createdAt,
  });


  factory InvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return InvitationModel(
      id: id,
      createdBy: map['createdBy'] ?? '',
      divisionId: map['divisionId'] ?? '',
      organizationId: map['organizationId'] ?? '',
      code: map['code'] ?? '',
      createdAt: map['createdAt'] ?? '',
      quizResult:
          QuizResult.fromMap(Map<String, dynamic>.from(map['quizResult'] ?? {}), ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdBy': createdBy,
      'divisionId': divisionId,
      'organizationId': organizationId,
      'code': code,
      'createdAt': createdAt,
      'quizResult': quizResult.toMap(),
    };
  }
}