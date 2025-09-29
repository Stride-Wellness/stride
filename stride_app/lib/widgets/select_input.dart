import 'package:flutter/material.dart';

class SelectOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool isMultiple;

  const SelectOption({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
    this.isMultiple = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor.withAlpha(100) : null,
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.outline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMultiple ? 10 : 180),
        ),
      ),
      child: Text(text),
    );
  }
}