
import 'package:flutter/material.dart';
import 'package:stride_app/constants/onboarding_question_graph.dart';
import 'package:stride_app/models/question_node_m.dart';

class OnboardingViewModel extends ChangeNotifier {

  PageController pageController = PageController();

  String _currentQuestionId = PersonalInfoQuestion.id;
  Map<String, List<String>> answers = {};
  Map<String, QuestionNode> questionMap = questionGraph;
  List<QuestionNode> questionList = [questionGraph[PersonalInfoQuestion.id]!];

  bool quizComplete = false;

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


