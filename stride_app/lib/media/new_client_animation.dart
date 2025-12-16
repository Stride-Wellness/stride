import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NewClientAnimation extends StatelessWidget {
  const NewClientAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/lotties/Caring family.json', // Update path as needed
        height: 180,
        fit: BoxFit.contain,
      ),
    );
  }
}