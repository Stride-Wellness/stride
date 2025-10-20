import 'package:flutter/material.dart';
import 'package:stride_app/constants/layout.dart';
import 'package:stride_app/views/create_account_v.dart';
import 'package:stride_app/views/onboarding_v.dart';
import 'package:stride_app/widgets/button.dart';

class GetStartedPageView extends StatelessWidget {
  const GetStartedPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            children: [
              const Text(
                "To get started, please tell us help us understand what you need from Stride!",
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              Expanded(child: Container()),
              LocalButton(text: "I am using Stride for myself.", navigateTo: () => OnboardingPage(), varient: ButtonVarient.primary),
              LocalButton(text: "I am helping other people.", navigateTo: () => CreateAccountScreenView(), varient: ButtonVarient.secondary),
              LocalButton(text: "I have a code.", navigateTo: () => CreateAccountScreenView(), varient: ButtonVarient.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class LocalButton extends StatelessWidget {
  const LocalButton({
    super.key,
    required this.text,
    required this.navigateTo,
    required this.varient,
  });

  final String text;
  final Widget Function() navigateTo;
  final ButtonVarient varient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KPadding.small),
      child: SizedBox(
        width: double.infinity,
        height: KSizes.buttonHeight,
        
        child: Button(
          varient: varient,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => navigateTo()
            ));
          },
          child: Text(text),
        ),
      ),
    );
  }
}
