import 'package:flutter/material.dart';

enum ButtonVariant {
  primary,
  secondary,
  danger,
  good,
  warn
}

class Button extends StatelessWidget {
  final ButtonVariant variant;
  final void Function()? onPressed;
  final Widget? child;

  const Button ({
    super.key,
    required this.variant,
    this.onPressed,
    this.child
  });

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    switch (variant) {
      case ButtonVariant.primary:
        return FilledButton(
          onPressed: onPressed,
          child: child,
        );
      case ButtonVariant.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          child: child,
        );
      case _:
        return Placeholder();
    }
  }
}
