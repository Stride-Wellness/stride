import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/provider_onboarding_quiz/vm.dart';
import 'package:stride_app/features/shared/widgets/labeled_text_field.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';

class ProviderOnboardingQuizView extends StatelessWidget {
  const ProviderOnboardingQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProviderOnboardingQuizVM(),
      child: const _ProviderOnboardingQuizContent(),
    );
  }
}

class _ProviderOnboardingQuizContent extends StatelessWidget {
  const _ProviderOnboardingQuizContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderOnboardingQuizVM>();

    return Scaffold(
      appBar: AppBar(title: const Text("Provider Registration")),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (vm.currentPage + 1) / vm.totalPages,
            ),
            Expanded(
              child: PageView(
                controller: vm.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _OrganizationInfoPage(),
                  _ServiceDetailsPage(),
                ],
              ),
            ),
            const _NavigationButtons(),
          ],
        ),
      ),
    );
  }
}

class _OrganizationInfoPage extends StatelessWidget {
  const _OrganizationInfoPage();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderOnboardingQuizVM>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Organization Information",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          LabeledTextField(
            label: "Organization Name",
            controller: vm.organizationNameController,
            textInputAction: TextInputAction.next,
          ),
          LabeledTextField(
            label: "Your Role/Title",
            controller: vm.roleController,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }
}

class _ServiceDetailsPage extends StatelessWidget {
  const _ServiceDetailsPage();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderOnboardingQuizVM>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Service Details",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            "How would you best describe your service?",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          RadioGroup(
            groupValue: vm.serviceType,
            onChanged: (value) => vm.serviceType = value.toString(),
            child: Column(
              children:
                  [
                        "Home Care Agency",
                        "Retirement Community",
                        "Assisted Living Facility",
                        "Independent Provider",
                        "Other",
                      ]
                      .map(
                        (type) => RadioListTile<String>(
                          title: Text(type),
                          value: type,
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "What services do you provide? (select all that apply)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...[
            "Personal Care",
            "Companionship",
            "Physical Therapy",
            "Occupational Therapy",
            "Memory Care",
            "Medication Management",
            "Transportation",
            "Meal Preparation",
          ].map(
            (service) => CheckboxListTile(
              title: Text(service),
              value: vm.servicesProvided.contains(service),
              onChanged: (checked) {
                if (checked == true) {
                  vm.addServiceProvided(service);
                } else {
                  vm.removeServiceProvided(service);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderOnboardingQuizVM>();

    return Padding(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Row(
        children: [
          if (vm.currentPage > 0) ...[
            Expanded(
              child: Button(
                variant: ButtonVariant.secondary,
                onPressed: vm.previousPage,
                child: const Text("Back"),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Button(
              variant: ButtonVariant.primary,
              onPressed: vm.canProceed()
                  ? () => _handleNext(context, vm)
                  : null,
              child: Text(
                vm.currentPage == vm.totalPages - 1 ? "Complete" : "Next",
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext(BuildContext context, ProviderOnboardingQuizVM vm) {
    if (vm.currentPage == vm.totalPages - 1) {
      Navigator.pop(context, {
        'answers': vm.getAnswersMap(),
        'questions': vm.getQuestionsTextMap(),
      });
    } else {
      vm.nextPage();
    }
  }
}
