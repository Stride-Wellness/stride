import 'package:flutter/material.dart';
import 'package:stride_core/repositories/invitations_repo.dart';

class InvitationOnboardingQuizVM extends ChangeNotifier {
  final InvitationsRepository invitationsRepo;

  InvitationOnboardingQuizVM({required this.invitationsRepo});

  final codeController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getQuizData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final invitation = await invitationsRepo.getInvitationByCode(codeController.text);
      
      if (invitation == null) {
        _errorMessage = 'Invalid invitation code';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final quizResult = invitation.quizResult;
      _isLoading = false;
      notifyListeners();
      
      return {
        'answers': quizResult.answers,
        'name': quizResult.answers['personal_info_question_name']!.first,
        'questions': quizResult.questions,
        'invitationId': invitation.id,
      };
    } catch (e) {
      _errorMessage = 'Error loading invitation: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}