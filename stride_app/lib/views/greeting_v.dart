import 'package:flutter/material.dart';
import 'package:stride_app/widgets/button.dart';
import 'package:stride_app/widgets/logo.dart';

class GreetingPage extends StatelessWidget {
  const GreetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Welcome to Stride",
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    Center(
                      child: StrideLogo(size: 200),
                    ),
                    SizedBox(height: 150),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: Button(
                          varient: ButtonVarient.primary,
                          onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                          child: const Text("Get Started")),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Button(
                          varient: ButtonVarient.secondary,
                            onPressed: () => Navigator.pushNamed(context, '/home'),
                          child: const Text("Sign In")),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
