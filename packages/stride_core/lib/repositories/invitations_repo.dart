import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_core/models/invitation_m.dart';
import 'package:stride_core/models/quiz_result_m.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/services/auth_service.dart';

class InvitationsRepository {
  static const String _collection = 'invitations';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService;

  InvitationsRepository({required AuthService authService})
      : _authService = authService;

  Future<InvitationModel?> getInvitationByCode(String code) async {
    final querySnapshot = await _db
        .collection(_collection)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final doc = querySnapshot.docs.first;
    return InvitationModel.fromMap(doc.data(), doc.id);
  }

  Future<InvitationModel?> getInvitationById(String id) async {
    final docSnapshot = await _db.collection(_collection).doc(id).get();

    if (!docSnapshot.exists) {
      return null;
    }

    return InvitationModel.fromMap(docSnapshot.data()!, docSnapshot.id);
  }

  Future<void> deleteInvitation(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Future<List<InvitationModel>> getInvitationsByUser_(String userId) async {
    final querySnapshot = await _db
        .collection(_collection)
        .where('createdBy', isEqualTo: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<InvitationModel>> getInvitationsByUser() async {
    final currentUser = await _authService.currentUser;
    if (currentUser == null) {
      throw Exception("No authenticated user found.");
    }

    return getInvitationsByUser_(currentUser.uid);
  }

  Future<InvitationModel> createInvitation_({
    required String userId,
    required Map<String, dynamic> answers,
    required Map<String, String> questions,
  }) async {
    var currentTime = Timestamp.now();
    final quizResult = QuizResult(
      id: '',
      name: "onboarding",
      answers: answers,
      questions: questions,
      userId: userId,
      timestamp: currentTime,
    );

    final invitationData = InvitationModel(
      id: '',
      quizResult: quizResult,
      createdBy: userId,
      code: await _generateInvitationCode(),
      createdAt: currentTime,
    );

    await _db.collection(_collection).add(invitationData.toMap());

    return invitationData;
  }

  Future<InvitationModel> createInvitation({
    required Map<String, dynamic> answers,
    required Map<String, String> questions,
  }) async {
    final currentUser = await _authService.currentUser;
    if (currentUser == null) {
      throw Exception("No authenticated user found.");
    }

    final invitation = await createInvitation_(
      userId: currentUser.uid,
      answers: answers,
      questions: questions,
    );
    return invitation;
  }

  Future<String> _generateInvitationCode() async {
    // TODO: Check for duplicates in database to ensure uniqueness
    final random = Random.secure();
    final code = (100000 + random.nextInt(900000)).toString();

    // Should check if code already exists:
    // final exists = await _db.collection(_collection).where('code', isEqualTo: code).get();
    // if (exists.docs.isNotEmpty) { retry... }

    return code;
  }
}
