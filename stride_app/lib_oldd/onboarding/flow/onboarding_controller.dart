import 'package:flutter/foundation.dart';

import '../models/nodes.dart';
import 'question_graph.dart';

/// Unified controller: all nodes are treated as (possibly single) multi-select.
class OnboardingController extends ChangeNotifier {
  final Map<String, QuestionNode> graph;
  final List<String> _history = [];
  final Map<String, Set<String>> selections = {}; // nodeId -> selected option ids
  final Map<String, Map<String, String>> textValues = {}; // nodeId -> {inputId: value}
  String _currentId;

  OnboardingController({Map<String, QuestionNode>? graph, String? startId})
      : graph = graph ?? onboardingGraph,
        _currentId = startId ?? 'start';

  QuestionNode get currentNode => graph[_currentId]!;
  List<String> get history => List.unmodifiable(_history);
  bool get canGoBack => _history.isNotEmpty;

  Set<String> _setFor(String nodeId) => selections[nodeId] ?? <String>{};

  bool isSelected(String optionId) => _setFor(_currentId).contains(optionId);

  void toggle(String optionId) {
    final node = currentNode;
    final set = _setFor(node.id);
    final newSet = Set<String>.from(set);

    final singleSelect = node.isSingleSelect;
    if (singleSelect) {
      // Replace with the single selection.
      newSet
        ..clear()
        ..add(optionId);
    } else {
      if (newSet.contains(optionId)) {
        newSet.remove(optionId);
      } else {
        if (newSet.length < node.maxSelections) {
          newSet.add(optionId);
        }
      }
    }
    selections[node.id] = newSet;
    notifyListeners();
  }

  bool canContinue() {
    final node = currentNode;
    final count = _setFor(node.id).length;
    final selectOk = count >= node.minSelections && count <= node.maxSelections;
    if (!selectOk) return false;
    // Validate text inputs.
    if (node.textInputs.isEmpty) return true;
    final values = textValues[node.id] ?? const {};
    for (final spec in node.textInputs) {
      final v = values[spec.id];
      if (!spec.validate(v)) return false;
    }
    return true;
  }

  void continueFlow() {
    final node = currentNode;
    if (!canContinue()) return;
    if (node.terminal || node.nextNodeId == null) {
      notifyListeners();
      return; // Terminal handled by UI.
    }
    _history.add(node.id);
    _currentId = node.nextNodeId!;
    notifyListeners();
  }

  void goBack() {
    if (!canGoBack) return;
    _currentId = _history.removeLast();
    notifyListeners();
  }

  void reset() {
    _history.clear();
    selections.clear();
    textValues.clear();
    _currentId = 'start';
    notifyListeners();
  }

  void updateTextValue(String inputId, String value) {
    final node = currentNode;
    final map = textValues[node.id] ?? <String, String>{};
    map[inputId] = value;
    textValues[node.id] = map;
    notifyListeners();
  }
}
