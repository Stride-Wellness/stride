import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CompletionCheckmarkAnimation extends StatelessWidget {
  const CompletionCheckmarkAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/lotties/succes2s.json', // Update path as needed
        height: 180,
        fit: BoxFit.contain,
        repeat: false
      ),
    );
  }
}