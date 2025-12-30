import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/client_onboarding_quiz/vm.dart';
import 'package:stride_app/features/shared/widgets/labeled_text_field.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';
import 'package:stride_ui/widgets/list_options.dart';

class ClientOnboardingQuizView extends StatelessWidget {
  const ClientOnboardingQuizView({super.key, required this.mode});

  final ClientOnboardingMode mode;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingQuizVM(mode: mode),
      child: const _ClientOnboardingQuizContent(),
    );
  }
}

class _ClientOnboardingQuizContent extends StatelessWidget {
  const _ClientOnboardingQuizContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingQuizVM>();

    return Scaffold(
      appBar: AppBar(title: Text(vm.pageTitle)),
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
                children: [
                  _PersonalInfoPage(vm: vm),
                  _HealthAndActivityPage(vm: vm),
                  _PreferencesAndGoalsPage(vm: vm),
                ],
              ),
            ),
            _NavigationButtons(vm: vm),
          ],
        ),
      ),
    );
  }
}

class _PersonalInfoPage extends StatelessWidget {
  const _PersonalInfoPage({required this.vm});

  final OnboardingQuizVM vm;

  @override
  Widget build(BuildContext context) {
    final prefix = vm.fromProvider ? "Client's " : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vm.fromProvider
                ? 'Client Personal Information'
                : 'Personal Information',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          LabeledTextField(
            label: '${prefix}Name',
            controller: vm.nameController,
            textInputAction: TextInputAction.next,
          ),
          LabeledTextField(
            label: '${prefix}Age',
            controller: vm.ageController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          _DropdownField(
            label: '${prefix}Sex',
            value: vm.sex,
            options: const ['Male', 'Female', 'Prefer not to say'],
            onChanged: (value) => vm.sex = value,
          ),
          LabeledTextField(
            label: '${prefix}Height (in inches or cm)',
            controller: vm.heightController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          LabeledTextField(
            label: '${prefix}Weight (in pounds or kg)',
            controller: vm.weightController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

class _HealthAndActivityPage extends StatelessWidget {
  const _HealthAndActivityPage({required this.vm});

  final OnboardingQuizVM vm;

  @override
  Widget build(BuildContext context) {
    final prefix = vm.fromProvider ? 'Client ' : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${prefix}Health & Activity',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'How often ${vm.fromProvider ? 'does your client' : 'do you'} currently do physical activity?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          RadioGroup(
            onChanged: (value) => vm.setActivityLevel(value?.toString()),
            groupValue: vm.activityLevel,
            child: Column(
              children: [
                ...const [
                  'Rarely or Never',
                  '1–2 times per week',
                  '3+ times per week',
                ].map(
                  (option) =>
                      RadioListTile<String>(title: Text(option), value: option),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "${vm.fromProvider ? "Client's " : ""}Health conditions (select all that apply)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _CheckboxGroup(
            options: const [
              'None of the above',
              'Diabetes',
              'Heart Disease',
              'High Blood Pressure',
              'Osteoporosis',
              'Arthritis',
              'Parkinson\'s Disease',
              'Stroke',
              'Dementia',
            ],
            isChecked: vm.healthConditions.contains,
            onChanged: vm.toggleHealthCondition,
          ),
          const SizedBox(height: 24),
          Text(
            "${vm.fromProvider ? "Client's " : ""}Pain or discomfort areas (select all that apply)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _CheckboxGroup(
            options: const [
              'No pain or discomfort',
              'Knees',
              'Hips',
              'Back',
              'Shoulders',
              'Neck',
              'Balance Problems',
              'History of Falls',
            ],
            isChecked: vm.painAreas.contains,
            onChanged: vm.togglePainArea,
          ),
        ],
      ),
    );
  }
}

class _PreferencesAndGoalsPage extends StatelessWidget {
  const _PreferencesAndGoalsPage({required this.vm});

  final OnboardingQuizVM vm;

  @override
  Widget build(BuildContext context) {
    final prefix = vm.fromProvider ? "Client's " : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${prefix}Preferences & Goals',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Types of exercise ${vm.fromProvider ? 'your client enjoys' : 'you enjoy'} (select all that apply)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _CheckboxGroup(
            options: const [
              'Walking',
              'Stretching',
              'Tai Chi',
              'Strengthening',
              'Cardio',
              'Balance',
              'Dancing',
              'Seated Workouts',
            ],
            isChecked: vm.exercisePreferences.contains,
            onChanged: vm.toggleExercisePreference,
          ),
          const SizedBox(height: 24),
          Text(
            "${vm.fromProvider ? "Client's " : ""}Equipment available at home",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _CheckboxGroup(
            options: const [
              'Sturdy Chair',
              'Resistance Bands',
              'Light Weights (1-5 lbs)',
              'Step or Stairs',
              'None - prefer no equipment workouts',
            ],
            isChecked: vm.equipment.contains,
            onChanged: vm.toggleEquipment,
          ),
          const SizedBox(height: 24),
          Text(
            "${vm.fromProvider ? "Client's " : ""}Mobility aids used",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _CheckboxGroup(
            options: const [
              'Wheelchair',
              'Walker',
              'Cane or Walking Stick',
              'None - No mobility aids needed',
            ],
            isChecked: vm.mobilityAids.contains,
            onChanged: vm.toggleMobilityAid,
          ),
          const SizedBox(height: 24),
          Text(
            "${vm.fromProvider ? "Client's " : ""}Main wellness goals",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _CheckboxGroup(
            options: const [
              'Joint Mobility - Improve flexibility and range of motion',
              'Balance - Improve stability and prevent falls',
              'Cognition - Improve mental sharpness and coordination',
            ],
            isChecked: vm.wellnessGoals.contains,
            onChanged: vm.toggleWellnessGoal,
          ),
          const SizedBox(height: 24),
          LabeledTextField(
            label: '${prefix}Favourite Hobbies or Interests',
            controller: vm.hobbiesController,
            maxLines: 3,
          ),
          LabeledTextField(
            label:
                '${vm.fromProvider ? 'What is your client' : 'What are you'} looking forward to in the next 2-4 weeks?',
            controller: vm.shortGoalsController,
            maxLines: 3,
          ),
          LabeledTextField(
            label:
                '${vm.fromProvider ? 'What is your client' : 'What are you'} looking forward to in the next 2-6 months?',
            controller: vm.longGoalsController,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Text(
            "${vm.fromProvider ? "Client's " : ""}Preferred energy level for workouts",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          RadioGroup(
            groupValue: vm.energyLevel,
            onChanged: (value) => vm.setEnergyLevel(value?.toString()),
            child: Column(
              children: [
                ...[
                  'Low - ${vm.fromProvider ? 'My client prefers' : 'I prefer'} gentle movements',
                  'Moderate - ${vm.fromProvider ? 'My client can handle' : 'I can handle'} some challenge',
                  'High - ${vm.fromProvider ? 'My client wants' : 'I want'} to push myself',
                ].map(
                  (level) =>
                      RadioListTile<String>(title: Text(level), value: level),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "${vm.fromProvider ? "Client's " : ""}Preferred time of day to exercise",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          RadioGroup(
            groupValue: vm.timePreference,
            onChanged: (value) => vm.setTimePreference(value?.toString()),
            child: Column(
              children: [
                ...['Morning', 'Afternoon', 'Evening'].map(
                  (time) =>
                      RadioListTile<String>(title: Text(time), value: time),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LabeledTextField(
            label:
                'Any extra notes or considerations${vm.fromProvider ? ' from your client' : ''}? (optional)',
            controller: vm.extraNotesController,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({required this.vm});

  final OnboardingQuizVM vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Row(
        children: [
          if (vm.currentPage > 0)
            Expanded(
              child: Button(
                variant: ButtonVariant.secondary,
                onPressed: vm.previousPage,
                child: const Text('Back'),
              ),
            ),
          if (vm.currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: Button(
              variant: ButtonVariant.primary,
              onPressed: vm.canProceed() ? () => _handleNext(context) : null,
              child: Text(
                vm.currentPage == vm.totalPages - 1 ? 'Complete' : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext(BuildContext context) {
    if (vm.currentPage == vm.totalPages - 1) {
      Navigator.pop(context, {
        'answers': vm.getAnswersMap(),
        'questions': vm.getQuestionsTextMap(),
        'name': vm.nameController.text,
      });
    } else {
      vm.nextPage();
    }
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _CheckboxGroup extends StatelessWidget {
  const _CheckboxGroup({
    required this.options,
    required this.isChecked,
    required this.onChanged,
  });

  final List<String> options;
  final bool Function(String) isChecked;
  final void Function(String, bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options
          .map(
            (value) => CheckboxListTile(
              title: Text(value),
              value: isChecked(value),
              onChanged: (checked) => onChanged(value, checked ?? false),
            ),
          )
          .toList(),
    );
  }
}
