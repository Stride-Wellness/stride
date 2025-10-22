import 'package:flutter/material.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_core/models/question_node_m.dart';
import 'select_input.dart';
import 'input.dart';
import 'dropdown_input.dart';

class ListOptionsWidget extends StatefulWidget {
  final List<QuestionOption> options;
  final int maxSelected;
  final int minSelected;
  final List<String> alreadySelected;
  final Function(List<String>) onSelectionChanged;
  final bool isMultiField;
  final Map<String, String> fieldValues; // For multi-field questions

  const ListOptionsWidget({
    super.key,
    required this.options,
    required this.maxSelected,
    required this.minSelected,
    required this.onSelectionChanged,
    this.alreadySelected = const [],
    this.isMultiField = false,
    this.fieldValues = const {},
  });

  @override
  State<ListOptionsWidget> createState() => _ListOptionsWidgetState();
}

class _ListOptionsWidgetState extends State<ListOptionsWidget> {
  List<String> selected = [];
  Map<String, String> fieldValues = {};

  @override
  void initState() {
    super.initState();
    selected = List.from(widget.alreadySelected);
    fieldValues = Map.from(widget.fieldValues);
  }

  void _updateFieldValue(String fieldKey, String value) {
    setState(() {
      fieldValues[fieldKey] = value;
    });
    // For multi-field questions, pass back field values as a special format
    if (widget.isMultiField) {
      List<String> result = fieldValues.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      widget.onSelectionChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.options.map((option) {
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: KPadding.small),
            child: _buildOptionWidget(option),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionWidget(QuestionOption option) {
    if (widget.isMultiField && option.fieldKey != null) {
      // Multi-field question
      switch (option.type) {
        case QuestionType.input:
          return InputWidget(
            hintText: option.question,
            initialValue: fieldValues[option.fieldKey],
            onChanged: (value) => _updateFieldValue(option.fieldKey!, value),
          );
        case QuestionType.dropdown:
          return DropdownInputWidget(
            hintText: option.question,
            options: option.dropdownOptions ?? [],
            initialValue: fieldValues[option.fieldKey],
            onChanged: (value) => _updateFieldValue(option.fieldKey!, value ?? ''),
          );
        case QuestionType.select:
          return SelectOption(
            text: option.question,
            isSelected: fieldValues[option.fieldKey] == option.question,
            onPressed: () => _updateFieldValue(option.fieldKey!, option.question),
            isMultiple: false,
          );
      }
    } else {
      // Regular single-field question
      switch (option.type) {
        case QuestionType.select:
          return SelectOption(
            text: option.question,
            isSelected: selected.contains(option.question),
            onPressed: () {
              setState(() {
                if (selected.contains(option.question)) {
                  selected.remove(option.question);
                } else if (selected.length < widget.maxSelected) {
                  selected.add(option.question);
                } else if (widget.maxSelected == 1) {
                  selected.clear();
                  selected.add(option.question);
                }
              });
              widget.onSelectionChanged(selected);
            },
            isMultiple: widget.maxSelected > 1,
          );
        case QuestionType.input:
          return InputWidget(
            hintText: option.question,
            initialValue: selected.isNotEmpty ? selected.first : null,
            onChanged: (value) {
              setState(() {
                selected.clear();
                if (value.isNotEmpty) {
                  selected.add(value);
                }
              });
              widget.onSelectionChanged(selected);
            },
          );
        case QuestionType.dropdown:
          return DropdownInputWidget(
            hintText: option.question,
            options: option.dropdownOptions ?? [],
            initialValue: selected.isNotEmpty ? selected.first : null,
            onChanged: (value) {
              setState(() {
                selected.clear();
                if (value != null && value.isNotEmpty) {
                  selected.add(value);
                }
              });
              widget.onSelectionChanged(selected);
            },
          );
      }
    }
  }
}
