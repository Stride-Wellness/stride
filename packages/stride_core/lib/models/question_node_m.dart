
enum QuestionType { select, input, dropdown, longInput }

class QuestionOption {
  final String question;
  final QuestionType type;
  final String? fieldKey; // For multi-field questions
  final List<String>? dropdownOptions; // For dropdown type

  QuestionOption(
    this.question, 
    this.type, {
    this.fieldKey,
    this.dropdownOptions,
  });
}

abstract class QuestionNode {
  String get questionId;
  int get maxSelected;
  int get minSelected;

  String text(Map<String, List<String>> answers);
  List<QuestionOption> options(Map<String, List<String>> answers);
  bool answered(Map<String, List<String>> answers);
  String? getNextId(Map<String, List<String>> answers);

  // For multi-field questions - override if needed
  bool get isMultiField => false;
  List<String> get requiredFields => [];
  
  // Helper to get sub-field value
  String? getFieldValue(Map<String, List<String>> answers, String fieldKey) {
    return answers['${questionId}_$fieldKey']?.first;
  }
  
  // Helper to set sub-field value
  void setFieldValue(Map<String, List<String>> answers, String fieldKey, String value) {
    answers['${questionId}_$fieldKey'] = [value];
  }
}
