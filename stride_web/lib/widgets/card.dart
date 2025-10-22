import 'package:flutter/material.dart';

class StrideCard extends StatelessWidget {
  final Widget child;

  const StrideCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(32),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: child,
        ),
      ),
    );
  }
}