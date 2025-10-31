import 'package:flutter/foundation.dart';
import 'package:stride_core/models/onboarding_quiz_result_m.dart';
import 'package:stride_core/repositories/user_repo.dart';

class ClientQuizListViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  ClientQuizListViewModel({required UserRepository userRepository})
      : _userRepository = userRepository;

  List<QuizResult> _quizzes = [];
  bool _isLoading = false;
  String? _error;

  List<QuizResult> get quizzes => _quizzes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, String> answers = {};

  Future<void> submitQuiz() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (answers.isEmpty) {
        throw Exception("No answers provided");
      }
      await _userRepository.saveQuizResult(
        answers: answers,
        name: "Checkin - ${DateTime.now().toIso8601String().split('T').first}"
      );
      await loadQuizzes(); // Refresh the quiz list after submission
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

    void updateAnswers(List<String> selected) {
    for (String entry in selected) {
      if (entry.contains(':')) {
        List<String> parts = entry.split(':');
        if (parts.length == 2) {
          String fieldKey = parts[0];
          String value = parts[1];
          answers[fieldKey] = value;
        }
      }
    }
    notifyListeners();
  }


  Future<void> loadQuizzes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _quizzes = (await _userRepository.getQuizzes());
      _quizzes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}