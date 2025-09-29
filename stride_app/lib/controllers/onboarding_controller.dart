import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:stride_app/constants/question_graph.dart';

class OnboardingController extends ChangeNotifier {

  PageController pageController = PageController();

  String _currentQuestionId = GenderQuestion.id;
  HashMap<String, List<String>> answers = HashMap();
  Map<String, QuestionNode> questionMap = questionGraph;
  List<QuestionNode> questionList = [questionGraph[GenderQuestion.id]!];

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

  void updateAnswers(index, List<String> selected) {
    answers[questionList[index].questionId] = selected;
    if (canProceed(index)) {
      String? nextId = questionList[index].getNextId(selected);
      if (nextId != null && questionList.length == index + 1) {
        questionList.add(questionMap[nextId]!);
      } else if (nextId != null && questionList.length > index + 1) {
        questionList.removeRange(index + 1, questionList.length);
        questionList.add(questionMap[nextId]!);
      }
    }
    notifyListeners();
  }
}


abstract class QuestionNode {
  String get questionId;
  int get maxSelected;
  int get minSelected;

  String text(HashMap<String, List<String>> answers);
  List<String> options(HashMap<String, List<String>> answers);
  bool answered(HashMap<String, List<String>> answers);
  String? getNextId(List<String> answers);
}