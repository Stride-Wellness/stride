import 'package:flutter/material.dart';

class StrideLogo extends StatelessWidget {
  const StrideLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return FlutterLogo(size: size);
  }
}