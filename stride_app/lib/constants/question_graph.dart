import 'dart:collection';

import 'package:stride_app/controllers/onboarding_controller.dart';

final questionGraph = {
  GenderQuestion.id: GenderQuestion(),
  BreedQuestion.id: BreedQuestion(),
  LabradorColorQuestion.id: LabradorColorQuestion(),
  NameQuestion.id: NameQuestion(),
};

class GenderQuestion extends QuestionNode {
  static const String id = "gender_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 1;

  @override
  String text(HashMap<String, List<String>> answers) {
    return "What is your dog's gender?";
  }

  @override
  List<String> options(HashMap<String, List<String>> answers) {
    return ["Male", "Female", "Other"];
  }

  @override
  bool answered(HashMap<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }

  @override
  String? getNextId(List<String> answers) {
    return BreedQuestion.id;
  }
}

class BreedQuestion extends QuestionNode {
  static const String id = "breed_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 1;

  @override
  String text(HashMap<String, List<String>> answers) {
    return "What is your dog's breed?";
  }

  @override
  List<String> options(HashMap<String, List<String>> answers) {
    return ["Labrador", "Poodle", "Beagle", "Other"];
  }

  @override
  bool answered(HashMap<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }


  @override
  String? getNextId(List<String> answers) {
    return answers.contains("Labrador") ? LabradorColorQuestion.id : NameQuestion.id;
  }
}

class LabradorColorQuestion extends QuestionNode {
  static const String id = "labrador_color_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 1;

  @override
  String text(HashMap<String, List<String>> answers) {
    return "What color is your Labrador?";
  }

  @override
  List<String> options(HashMap<String, List<String>> answers) {
    return ["Black", "Chocolate", "Yellow"];
  }

  @override
  bool answered(HashMap<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }


  @override
  String? getNextId(List<String> answers) {
    return NameQuestion.id;
  }
}

class NameQuestion extends QuestionNode {
  static const String id = "name_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 1;

  @override
  String text(HashMap<String, List<String>> answers) {
    if (answers["gender_question"]?.contains("Male") ?? false) {
      return "What is his name?";
    } else if (answers["gender_question"]?.contains("Female") ?? false) {
      return "What is her name?";
    } else {
      return "What is their name?";
    }
  }

  @override
  List<String> options(HashMap<String, List<String>> answers) {
    return ["Buddy", "Bella", "Charlie", "Lucy", "Max", "Daisy"];
  }

  @override
  bool answered(HashMap<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }


  @override
  String? getNextId(List<String> answers) {
    return null; // End of graph
  }
}