import 'package:flutter/material.dart';
import 'package:stride_app/controllers/auth_state_controller.dart';
import 'package:stride_core/models/quiz_result_m.dart';
import 'package:stride_core/repositories/invitations_repo.dart';

class ProviderAssistedClientSignupVM extends ChangeNotifier {
  final InvitationsRepository invitationsRepo;
  final AuthStateController authController;
  static const String quizName = "Client Onboarding Quiz";

  final String instructionText =
      "Please fill out the onboarding form for your new client. "
      "We will then send them an email or give you a code that they can use to finish setting up their account.";

  ProviderAssistedClientSignupVM({
    required this.invitationsRepo,
    required this.authController,
  });

  /// Handles the completion of the onboarding quiz by creating an invitation.
  Future<int> createClientInvitation(Map<String, dynamic> quizResult) async {
    final questions = quizResult["questions"];
    final answers = quizResult["answers"];

    final invitation = await invitationsRepo.createInvitation(
      user: authController.user!,
      answers: answers,
      questions: questions,
    );

    return int.parse(invitation.code);
  }
}
