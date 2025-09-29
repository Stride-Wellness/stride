// No Flutter imports needed; pure data models.

// Minimal unified models: everything is a (possibly single) multi-select step.

class AnswerOption {
  final String id;
  final String label;
  final String? description;
  const AnswerOption({required this.id, required this.label, this.description});
}

class QuestionNode {
  final String id;
  final String prompt;
  final List<AnswerOption> options;
  final int minSelections; // inclusive
  final int maxSelections; // inclusive
  final String? helperText;
  final String? nextNodeId; // null if terminal
  final bool terminal; // if true we show Finish label
  // Optional free-form text inputs required at this step.
  final List<TextInputSpec> textInputs;
  const QuestionNode({
    required this.id,
    required this.prompt,
    required this.options,
    required this.minSelections,
    required this.maxSelections,
    this.helperText,
    this.nextNodeId,
    this.terminal = false,
    this.textInputs = const [],
  });

  bool get isSingleSelect => minSelections == 1 && maxSelections == 1;
}

/// Specification for a text input field shown on a question node.
class TextInputSpec {
  final String id; // unique within node
  final String label; // label shown to user
  final String? placeholder;
  final bool required;
  final String? pattern; // regex body (without ^ $) to match entire value
  final String? errorMessage; // message to show when pattern / required fails

  const TextInputSpec({
    required this.id,
    required this.label,
    this.placeholder,
    this.required = true,
    this.pattern,
    this.errorMessage,
  });

  bool validate(String? value) {
    final v = value?.trim() ?? '';
    if (required && v.isEmpty) return false;
    if (v.isEmpty && !required) return true; // optional empty ok
    if (pattern != null && pattern!.isNotEmpty) {
      try {
  final re = RegExp('^${pattern!}\$' , caseSensitive: false);
        return re.hasMatch(v);
      } catch (_) {
        return false; // invalid pattern definition
      }
    }
    return true;
  }
}
