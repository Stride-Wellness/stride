import 'package:flutter/material.dart';
import 'package:stride_app/constants/layout.dart';
import 'select_input.dart';

class MultiSelectWidget extends StatefulWidget {
  final List<String> options;
  final int maxSelected;
  final int minSelected;
  final List<String> alreadySelected;
  final Function(List<String>) onSelectionChanged;

  const MultiSelectWidget({
    super.key,
    required this.options,
    required this.maxSelected,
    required this.minSelected,
    required this.onSelectionChanged,
    this.alreadySelected = const [],
  });

  @override
  State<MultiSelectWidget> createState() => _MultiSelectWidgetState();
}

class _MultiSelectWidgetState extends State<MultiSelectWidget> {
  List<String> selected = [];

  @override
  void initState() {
    super.initState();
    selected = List.from(widget.alreadySelected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.options.map((option) {
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: KPadding.small),
            child: SelectOption(
              text: option,
              isSelected: selected.contains(option),
              onPressed: () {
                setState(() {
                  if (selected.contains(option)) {
                    selected.remove(option);
                  } else if (selected.length < widget.maxSelected) {
                    selected.add(option);
                  } else if (widget.maxSelected == 1) {
                    selected.clear();
                    selected.add(option);
                  }
                });
                widget.onSelectionChanged(selected);
              },
              isMultiple: widget.maxSelected > 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}
