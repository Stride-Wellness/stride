import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:stride_app/constants/layout.dart';
import 'package:stride_app/controllers/onboarding_controller.dart';
import 'package:stride_app/widgets/button.dart';
import 'package:stride_app/widgets/select.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    var onboardingController = context.watch<OnboardingController>();
    var currentPage = 0;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SmoothPageIndicator(
              controller: onboardingController.pageController,
              count: 5,
              effect: WormEffect(
                activeDotColor: Theme.of(context).primaryColor,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: onboardingController.pageController,
                physics: onboardingController.canProceed(currentPage)
                    ? null
                    : NeverScrollableScrollPhysics(),
                onPageChanged: (value) {
                  currentPage = value;
                },
                itemCount: onboardingController.questionList.length,
                itemBuilder: (context, index) {
                  return MultipleSelectQuestion(
                    question: onboardingController.getQuestion(index).text( onboardingController.answers),
                    options: onboardingController.getQuestion(index).options( onboardingController.answers),
                    maxSelected: onboardingController.getQuestion(index).maxSelected,
                    minSelected: onboardingController.getQuestion(index).minSelected,
                    onSelectionChanged: (selections) {
                      onboardingController.updateAnswers(index, selections);
                    },
                    alreadySelected: onboardingController.answers[onboardingController.getQuestion(index).questionId] ?? [],
                  );  
                },
              ),
            ),
            OnboardingNavigation(),
          ],
        ),
      ),
    );
  }
}

class MultipleSelectQuestion extends StatelessWidget {
  const MultipleSelectQuestion({
    super.key,
    required this.question,
    required this.options,
    required this.onSelectionChanged,
    this.maxSelected = 1,
    this.minSelected = 1,
    this.alreadySelected = const [],
  });

  final List<String> alreadySelected;
  final String question;
  final List<String> options;
  final int maxSelected;
  final int minSelected;
  final Function(List<String>) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 100),
            Text(question, style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 50),
            MultiSelectWidget(
              options: options,
              maxSelected: maxSelected,
              minSelected: minSelected,
              onSelectionChanged: onSelectionChanged,
              alreadySelected: alreadySelected,
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class OnboardingNavigation extends StatelessWidget {
  const OnboardingNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KPadding.pagePadding,
      ).copyWith(bottom: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Button(
              varient: ButtonVarient.secondary,
              onPressed: () {
                // Handle back action
              },
              child: const Text("Back"),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Button(
              varient: ButtonVarient.primary,
              onPressed: () {
                // Handle next action
              },
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    );
  }
}
