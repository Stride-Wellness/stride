import 'package:flutter/material.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_app/views/get_started_options_page_v.dart';
import 'package:stride_app/views/sign_in_page_v.dart';
import 'package:stride_ui/widgets/button.dart';
import 'package:stride_ui/widgets/logo.dart';

class GreetingPage extends StatelessWidget {
  const GreetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            children: [
              // Title
              Text(
                "Welcome to Stride",
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 100),
              Center(child: StrideLogo(size: 200)),

              // This Expanded pushes everything below to the bottom
              Expanded(child: Container()),

              // Buttons at the bottom
              SizedBox(
                height: 50,
                width: double.infinity,
                child: Button(
                  varient: ButtonVarient.primary,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GetStartedPageView(),
                    ),
                  ),
                  child: const Text("Get Started"),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Button(
                  varient: ButtonVarient.secondary,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreenView(),
                    ),
                  ),
                  child: const Text("Sign In"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
