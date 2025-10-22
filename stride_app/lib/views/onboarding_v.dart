import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_core/models/question_node_m.dart';
import 'package:stride_core/view_models/onboarding_vm.dart';
import 'package:stride_ui/widgets/button.dart';
import 'package:stride_ui/widgets/list_options.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    var onboardingViewModel = context.watch<OnboardingViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SmoothPageIndicator(
              controller: onboardingViewModel.pageController,
              count: onboardingViewModel.questionList.length,
              effect: WormEffect(
                activeDotColor: Theme.of(context).primaryColor,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: onboardingViewModel.pageController,
                physics: onboardingViewModel.canProceed(currentPage)
                    ? null
                    : NeverScrollableScrollPhysics(),
                onPageChanged: (value) {
                  if (onboardingViewModel.quizComplete) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                  setState(() {
                    currentPage = value;
                  });
                },
                itemBuilder: (context, index) {
                  var question = onboardingViewModel.getQuestion(index);
                  return MultipleSelectQuestion(
                    question: question.text(onboardingViewModel.answers),
                    options: question.options(onboardingViewModel.answers),
                    maxSelected: question.maxSelected,
                    minSelected: question.minSelected,
                    isMultiField: question.isMultiField,
                    fieldValues: onboardingViewModel.getFieldValues(index),
                    onSelectionChanged: (selections) {
                      onboardingViewModel.updateAnswers(index, selections);
                    },
                    alreadySelected:
                        onboardingViewModel.answers[question.questionId] ?? [],
                  );
                },
              ),
            ),
            if (onboardingViewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                child: Text(
                  onboardingViewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            OnboardingNavigation(currentPage: currentPage),
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
    this.isMultiField = false,
    this.fieldValues = const {},
  });

  final List<String> alreadySelected;
  final String question;
  final List<QuestionOption> options;
  final int maxSelected;
  final int minSelected;
  final bool isMultiField;
  final Map<String, String> fieldValues;
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
            ListOptionsWidget(
              options: options,
              maxSelected: maxSelected,
              minSelected: minSelected,
              isMultiField: isMultiField,
              fieldValues: fieldValues,
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
  final int currentPage;

  const OnboardingNavigation({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    var onboardingController = context.watch<OnboardingViewModel>();
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
                onboardingController.pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text("Back"),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Button(
              varient: ButtonVarient.primary,
              onPressed:
                  (onboardingController.isLoading ||
                      (!onboardingController.quizComplete &&
                          !onboardingController.canProceed(currentPage)))
                  ? null
                  : () async {
                      if (onboardingController.quizComplete) {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await onboardingController
                            .createAccountAndSaveQuiz();
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Account created! Please check your email for verification.',
                              ),
                            ),
                          );
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          if (onboardingController.errorMessage != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  onboardingController.errorMessage!,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else if (onboardingController.canProceed(currentPage)) {
                        onboardingController.pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
              child: onboardingController.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      onboardingController.quizComplete
                          ? "Create Account"
                          : "Next",
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
