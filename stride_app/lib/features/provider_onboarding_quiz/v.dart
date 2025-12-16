import 'package:flutter/material.dart';
import 'package:stride_app/features/provider_onboarding_quiz/vm.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';

class ProviderOnboardingQuizView extends StatefulWidget {
  const ProviderOnboardingQuizView({super.key});

  @override
  State<ProviderOnboardingQuizView> createState() =>
      _ProviderOnboardingQuizViewState();
}

class _ProviderOnboardingQuizViewState
    extends State<ProviderOnboardingQuizView> {
  late ProviderOnboardingQuizVM _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProviderOnboardingQuizVM();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Provider Registration")),
          body: SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_viewModel.currentPage + 1) / _viewModel.totalPages,
                ),
                Expanded(
                  child: PageView(
                    controller: _viewModel.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildOrganizationInfoPage(),
                      _buildServiceDetailsPage(),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrganizationInfoPage() {
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
          _buildTextField(
            "Organization Name",
            _viewModel.organizationNameController,
          ),
          _buildTextField("Your Role/Title", _viewModel.roleController),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsPage() {
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

          // Service Type
          Text(
            "What type of service do you provide?",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          RadioGroup(
            groupValue: _viewModel.serviceType,
            onChanged: (value) {
              _viewModel.serviceType = value;
            },
            child: Column(
              children: [
                ...[
                  "Home Care Agency",
                  "Retirement Community",
                  "Assisted Living Facility",
                  "Independent Provider",
                  "Other",
                ].map(
                  (type) =>
                      RadioListTile<String>(title: Text(type), value: type),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Services Provided
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
              value: _viewModel.servicesProvided.contains(service),
              onChanged: (checked) {
                if (checked == true) {
                  _viewModel.servicesProvided.add(service);
                } else {
                  _viewModel.servicesProvided.remove(service);
                }
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Row(
        children: [
          if (_viewModel.currentPage > 0)
            Expanded(
              child: Button(
                variant: ButtonVariant.secondary,
                onPressed: () => _viewModel.previousPage(),
                child: const Text("Back"),
              ),
            ),
          if (_viewModel.currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: Button(
              variant: ButtonVariant.primary,
              onPressed: !_viewModel.canProceed() ? null : () => _handleNext(),
              child: Text(
                _viewModel.currentPage == _viewModel.totalPages - 1
                    ? "Complete"
                    : "Next",
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_viewModel.currentPage == _viewModel.totalPages - 1) {
      // Return the quiz data
      Navigator.pop(context, {
        'answers': _viewModel.getAnswersMap(),
        'questions': _viewModel.getQuestionsTextMap(),
      });
    } else {
      _viewModel.nextPage();
    }
  }
}
