import 'package:flutter/material.dart';

enum ButtonVarient {
  primary,
  secondary,
  danger,
  good,
  warn
}

class Button extends StatelessWidget {
  final ButtonVarient varient;
  final void Function()? onPressed;
  final Widget? child;

  const Button ({
    super.key,
    required this.varient,
    this.onPressed,
    this.child
  });

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    switch (varient) {
      case ButtonVarient.primary:
        return FilledButton(
          onPressed: onPressed,
          child: child,
        );
      case _:
        return ElevatedButton(
          onPressed: onPressed,
          child: child,
        );
    }
  }
}
