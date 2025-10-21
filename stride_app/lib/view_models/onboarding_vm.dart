
import 'package:flutter/material.dart';
import 'package:stride_app/constants/onboarding_question_graph.dart';
import 'package:stride_app/models/question_node_m.dart';
import 'package:stride_app/repositories/user_repo.dart';

class OnboardingViewModel extends ChangeNotifier {
  final UserRepository userRepo;

  OnboardingViewModel({required this.userRepo});

  PageController pageController = PageController();

  String _currentQuestionId = PersonalInfoQuestion.id;
  Map<String, List<String>> answers = {};
  Map<String, QuestionNode> questionMap = questionGraph;
  List<QuestionNode> questionList = [questionGraph[PersonalInfoQuestion.id]!];

  bool quizComplete = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String get currentQuestionId => _currentQuestionId;
  QuestionNode get currentQuestion => questionMap[_currentQuestionId]!;

  QuestionNode getQuestion(index) {
    if (index >= questionList.length) {
      return questionList.last;
    }
    return questionList[index];
  }

  bool canProceed(index) {
    return questionList[index].answered(answers);
  }

  // return true if the questionnaire is complete
  void updateAnswers(index, List<String> selected) {
    QuestionNode question = questionList[index];
    
    if (question.isMultiField) {
      // Handle multi-field questions
      // Parse the field:value format and store each field separately
      for (String entry in selected) {
        if (entry.contains(':')) {
          List<String> parts = entry.split(':');
          if (parts.length == 2) {
            String fieldKey = parts[0];
            String value = parts[1];
            answers['${question.questionId}_$fieldKey'] = [value];
          }
        }
      }
    } else {
      // Handle regular single-field questions
      answers[question.questionId] = selected;
    }
    
    if (canProceed(index)) {
      String? nextId = questionList[index].getNextId(answers);
      if (nextId != null && questionList.length == index + 1) {
        questionList.add(questionMap[nextId]!);
      } else if (nextId != null && questionList.length > index + 1) {
        questionList.removeRange(index + 1, questionList.length);
        questionList.add(questionMap[nextId]!);
      }
      if (nextId == null) {
        quizComplete = true;
      }
    }
    notifyListeners();
  }

  // Extracts email and password from answers map
  String? get email => answers['email_password_question_email']?.first;
  String? get password => answers['email_password_question_password']?.first;
  String? get name => answers['personal_info_question_name']?.first;

  // Returns quiz answers minus email/password fields
  Map<String, dynamic> getQuizAnswersForResult() {
    final filtered = <String, dynamic>{};
    answers.forEach((key, value) {
      if (!key.startsWith('email_password_question_')) {
        filtered[key] = value;
      }
    });
    return filtered;
  }

  Future<bool> createAccountAndSaveQuiz() async {
    if (email == null ||
        password == null ||
        email!.isEmpty ||
        password!.isEmpty) {
      _errorMessage = "Email and password are required.";
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Use the high-level method from UserRepository
      await userRepo.createClientFromOnboarding(
        name: name!,
        email: email!,
        password: password!,
        quizAnswers: getQuizAnswersForResult(),
        sendEmailVerification: true,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper method to get field values for multi-field questions
  Map<String, String> getFieldValues(int index) {
    QuestionNode question = questionList[index];
    if (!question.isMultiField) return {};
    
    Map<String, String> fieldValues = {};
    for (String field in question.requiredFields) {
      String? value = question.getFieldValue(answers, field);
      if (value != null) {
        fieldValues[field] = value;
      }
    }
    return fieldValues;
  }
}


