import 'package:flutter/material.dart';
import 'package:stride_app/features/client_onboarding_quiz/vm.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';

class ClientOnboardingQuizView extends StatefulWidget {
  final ClientOnboardingMode mode;
  const ClientOnboardingQuizView({super.key, required this.mode});

  @override
  State<ClientOnboardingQuizView> createState() =>
      _ClientOnboardingQuizViewState();
}

class _ClientOnboardingQuizViewState extends State<ClientOnboardingQuizView> {
  late OnboardingQuizVM _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingQuizVM(mode: widget.mode);
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
          appBar: AppBar(title: Text(_viewModel.pageTitle)),
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
                      _buildPersonalInfoPage(),
                      _buildHealthAndActivityPage(),
                      _buildPreferencesAndGoalsPage(),
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

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${_viewModel.fromProvider ? "Client " : ""}Personal Information",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            "${_viewModel.fromProvider ? "Client's " : ""}Name",
            _viewModel.nameController,
          ),
          _buildTextField(
            "${_viewModel.fromProvider ? "Client's " : ""}Age",
            _viewModel.ageController,
            keyboardType: TextInputType.number,
          ),
          _buildDropdown(
            "${_viewModel.fromProvider ? "Client's " : ""}Sex",
            _viewModel.sex,
            [
            "Male",
            "Female",
            "Prefer not to say",
          ], (value) => _viewModel.sex = value),
          _buildTextField(
            "${_viewModel.fromProvider ? "Client's " : ""}Height (in inches or cm)",
            _viewModel.heightController,
            keyboardType: TextInputType.number,
          ),
          _buildTextField(
            "${_viewModel.fromProvider ? "Client's " : ""}Weight (in pounds or kg)",
            _viewModel.weightController,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAndActivityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${_viewModel.fromProvider ? "Client " : ""}Health & Activity",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Activity Level
          Text(
            "How often ${_viewModel.fromProvider ? "does your client" : "do you"} currently do physical activity?",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          RadioGroup(
            onChanged: (value) => _viewModel.activityLevel = value.toString(),
            groupValue: _viewModel.activityLevel,
            child: Column(
              children: [
                ...[
                  "Rarely or Never",
                  "1–2 times per week",
                  "3+ times per week",
                ].map(
                  (option) =>
                      RadioListTile<String>(title: Text(option), value: option),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Health Conditions
          Text(
            "${_viewModel.fromProvider ? "Client's " : ""}Health conditions (select all that apply)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...[
            "None of the above",
            "Diabetes",
            "Heart Disease",
            "High Blood Pressure",
            "Osteoporosis",
            "Arthritis",
            "Parkinson's Disease",
            "Stroke",
            "Dementia",
          ].map(
            (condition) => CheckboxListTile(
              title: Text(condition),
              value: _viewModel.healthConditions.contains(condition),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  if (condition == "None of the above") {
                    _viewModel.healthConditions.clear();
                  } else {
                    _viewModel.healthConditions.remove("None of the above");
                  }
                  _viewModel.healthConditions.add(condition);
                } else {
                  _viewModel.healthConditions.remove(condition);
                }
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Pain & Mobility
          Text(
            "${_viewModel.fromProvider ? "Client's " : ""}Pain or discomfort areas (select all that apply)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...[
            "No pain or discomfort",
            "Knees",
            "Hips",
            "Back",
            "Shoulders",
            "Neck",
            "Balance Problems",
            "History of Falls",
          ].map(
            (area) => CheckboxListTile(
              title: Text(area),
              value: _viewModel.painAreas.contains(area),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  if (area == "No pain or discomfort") {
                    _viewModel.painAreas.clear();
                  } else {
                    _viewModel.painAreas.remove("No pain or discomfort");
                  }
                  _viewModel.painAreas.add(area);
                } else {
                  _viewModel.painAreas.remove(area);
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesAndGoalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${_viewModel.fromProvider ? "Client's " : ""}Preferences & Goals",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Exercise Preferences
          Text(
            "Types of exercise ${_viewModel.fromProvider ? "your client enjoys" : "you enjoy"} (select all that apply)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...[
            "Walking",
            "Stretching",
            "Tai Chi",
            "Strengthening",
            "Cardio",
            "Balance",
            "Dancing",
            "Seated Workouts",
          ].map(
            (exercise) => CheckboxListTile(
              title: Text(exercise),
              value: _viewModel.exercisePreferences.contains(exercise),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _viewModel.exercisePreferences.add(exercise);
                } else {
                  _viewModel.exercisePreferences.remove(exercise);
                }
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Equipment Available
          Text(
            "${_viewModel.fromProvider ? "Client's " : ""}Equipment available at home",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...[
            "Sturdy Chair",
            "Resistance Bands",
            "Light Weights (1-5 lbs)",
            "Step or Stairs",
            "None - prefer no equipment workouts",
          ].map(
            (equipment) => CheckboxListTile(
              title: Text(equipment),
              value: _viewModel.equipment.contains(equipment),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  if (equipment == "None - prefer no equipment workouts") {
                    _viewModel.equipment.clear();
                  } else {
                    _viewModel.equipment.remove(
                      "None - prefer no equipment workouts",
                    );
                  }
                  _viewModel.equipment.add(equipment);
                } else {
                  _viewModel.equipment.remove(equipment);
                }
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Mobility Aids
          Text(
            "${_viewModel.fromProvider ? "Client's " : ""}Mobility aids used",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...[
            "Wheelchair",
            "Walker",
            "Cane or Walking Stick",
            "None - No mobility aids needed",
          ].map(
            (aid) => CheckboxListTile(
              title: Text(aid),
              value: _viewModel.mobilityAids.contains(aid),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  if (aid == "None - No mobility aids needed") {
                    _viewModel.mobilityAids.clear();
                  } else {
                    _viewModel.mobilityAids.remove(
                      "None - No mobility aids needed",
                    );
                  }
                  _viewModel.mobilityAids.add(aid);
                } else {
                  _viewModel.mobilityAids.remove(aid);
                }
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Wellness Goals
          Text(
            "${_viewModel.fromProvider ? "Client's " : ""}Main wellness goals",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...[
            "Joint Mobility - Improve flexibility and range of motion",
            "Balance - Improve stability and prevent falls",
            "Cognition - Improve mental sharpness and coordination",
          ].map(
            (goal) => CheckboxListTile(
              title: Text(goal),
              value: _viewModel.wellnessGoals.contains(goal),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _viewModel.wellnessGoals.add(goal);
                } else {
                  _viewModel.wellnessGoals.remove(goal);
                }
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Hobbies & Goals
          _buildTextField(
            "${_viewModel.fromProvider ? "Client's " : ""}Favourite Hobbies or Interests",
            _viewModel.hobbiesController,
            maxLines: 3,
          ),
          _buildTextField(
            "${_viewModel.fromProvider ? "What is your client" : "What are you"} looking forward to in the next 2-4 weeks?",
            _viewModel.shortGoalsController,
            maxLines: 3,
          ),
          _buildTextField(
            "${_viewModel.fromProvider ? "What is your client" : "What are you"} looking forward to in the next 2-6 months?",
            _viewModel.longGoalsController,
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          // Energy Level
          Text(
            "${_viewModel.fromProvider ? "Client's " : ""}Preferred energy level for workouts",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          RadioGroup(
            groupValue: _viewModel.energyLevel,
            onChanged: (value) => setState(() {
              _viewModel.energyLevel = value;
            }),
            child: Column(
              children: [
                ...[
                  "Low - ${_viewModel.fromProvider ? "My client prefers" : "I prefer"} gentle movements",
                  "Moderate - ${_viewModel.fromProvider ? "My client can handle" : "I can handle"} some challenge",
                  "High - ${_viewModel.fromProvider ? "My client wants" : "I want"} to push myself",
                ].map(
                  (level) =>
                      RadioListTile<String>(title: Text(level), value: level),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Time Preference
          Text(
            "${_viewModel.fromProvider ? "Client's " : ""}Preferred time of day to exercise",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          RadioGroup(
            groupValue: _viewModel.timePreference,
            onChanged: (value) => _viewModel.timePreference = value,
            child: Column(
              children: [
                ...["Morning", "Afternoon", "Evening"].map(
                  (time) =>
                      RadioListTile<String>(title: Text(time), value: time),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Extra Notes
          _buildTextField(
            "Any extra notes or considerations${_viewModel.fromProvider ? " from your client" : ""}? (optional)",
            _viewModel.extraNotesController,
            maxLines: 4,
          ),
        ],
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
        'name': _viewModel.nameController.text,
      });
    } else {
      _viewModel.nextPage();
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (newValue) {
          setState(() {
            onChanged(newValue);
          });
        },
      ),
    );
  }
}
