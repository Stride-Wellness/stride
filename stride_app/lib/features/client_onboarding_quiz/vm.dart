import 'package:flutter/material.dart';

enum ClientOnboardingMode {
  clientSelfRegistration,
  providerAssistedRegistration,
}

class OnboardingQuizVM extends ChangeNotifier {
  final ClientOnboardingMode mode;

  get fromProvider => mode == ClientOnboardingMode.providerAssistedRegistration;

  get pageTitle => fromProvider ? "Client Onboarding" : "Welcome to Stride";

  OnboardingQuizVM({
    required this.mode,
  }) {
    for (final controller in _allControllers) {
      controller.addListener(notifyListeners);
    }
  }

  final PageController pageController = PageController();
  int _currentPage = 0;
  int get currentPage => _currentPage;
  set currentPage(int value) {
    if (_currentPage != value) {
      _currentPage = value;
      notifyListeners();
    }
  }

  final int totalPages = 3; // Removed account creation page

  // Page 1: Personal Info
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? _sex;
  String? get sex => _sex;
  set sex(String? value) {
    if (_sex != value) {
      _sex = value;
      notifyListeners();
    }
  }
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  // Page 2: Health & Activity
  String? _activityLevel;
  String? get activityLevel => _activityLevel;
  set activityLevel(String? value) {
    if (_activityLevel != value) {
      _activityLevel = value;
      notifyListeners();
    }
  }

  final Set<String> _healthConditions = {};
  Set<String> get healthConditions => _healthConditions;
  void addHealthCondition(String value) {
    if (_healthConditions.add(value)) notifyListeners();
  }
  void removeHealthCondition(String value) {
    if (_healthConditions.remove(value)) notifyListeners();
  }

  final Set<String> _painAreas = {};
  Set<String> get painAreas => _painAreas;
  void addPainArea(String value) {
    if (_painAreas.add(value)) notifyListeners();
  }
  void removePainArea(String value) {
    if (_painAreas.remove(value)) notifyListeners();
  }

  // Page 3: Preferences & Goals
  final Set<String> _exercisePreferences = {};
  Set<String> get exercisePreferences => _exercisePreferences;
  void addExercisePreference(String value) {
    if (_exercisePreferences.add(value)) notifyListeners();
  }
  void removeExercisePreference(String value) {
    if (_exercisePreferences.remove(value)) notifyListeners();
  }

  final Set<String> _equipment = {};
  Set<String> get equipment => _equipment;
  void addEquipment(String value) {
    if (_equipment.add(value)) notifyListeners();
  }
  void removeEquipment(String value) {
    if (_equipment.remove(value)) notifyListeners();
  }

  final Set<String> _mobilityAids = {};
  Set<String> get mobilityAids => _mobilityAids;
  void addMobilityAid(String value) {
    if (_mobilityAids.add(value)) notifyListeners();
  }
  void removeMobilityAid(String value) {
    if (_mobilityAids.remove(value)) notifyListeners();
  }

  final Set<String> _wellnessGoals = {};
  Set<String> get wellnessGoals => _wellnessGoals;
  void addWellnessGoal(String value) {
    if (_wellnessGoals.add(value)) notifyListeners();
  }
  void removeWellnessGoal(String value) {
    if (_wellnessGoals.remove(value)) notifyListeners();
  }

  final TextEditingController hobbiesController = TextEditingController();
  final TextEditingController shortGoalsController = TextEditingController();
  final TextEditingController longGoalsController = TextEditingController();

  String? _energyLevel;
  String? get energyLevel => _energyLevel;
  set energyLevel(String? value) {
    if (_energyLevel != value) {
      _energyLevel = value;
      notifyListeners();
    }
  }

  String? _timePreference;
  String? get timePreference => _timePreference;
  set timePreference(String? value) {
    if (_timePreference != value) {
      _timePreference = value;
      notifyListeners();
    }
  }

  final TextEditingController extraNotesController = TextEditingController();

  List<TextEditingController> get _allControllers => [
        nameController,
        ageController,
        heightController,
        weightController,
        hobbiesController,
        shortGoalsController,
        longGoalsController,
        extraNotesController,
      ];

  bool canProceed() {
    switch (currentPage) {
      case 0:
        return nameController.text.isNotEmpty &&
            ageController.text.isNotEmpty &&
            sex != null &&
            heightController.text.isNotEmpty &&
            weightController.text.isNotEmpty;
      case 1:
        return activityLevel != null &&
            healthConditions.isNotEmpty &&
            painAreas.isNotEmpty;
      case 2:
        return exercisePreferences.isNotEmpty &&
            equipment.isNotEmpty &&
            mobilityAids.isNotEmpty &&
            wellnessGoals.isNotEmpty &&
            hobbiesController.text.isNotEmpty &&
            shortGoalsController.text.isNotEmpty &&
            longGoalsController.text.isNotEmpty &&
            energyLevel != null &&
            timePreference != null;
      default:
        return false;
    }
  }

  void nextPage() {
    if (currentPage < totalPages - 1) {
      currentPage++;
      pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      currentPage--;
      pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  // Convert to Firebase format
  Map<String, List<String>> getAnswersMap() {
    return {
      'personal_info_question_name': [nameController.text],
      'personal_info_question_age': [ageController.text],
      'personal_info_question_sex': [sex ?? ''],
      'personal_info_question_height': [heightController.text],
      'personal_info_question_weight': [weightController.text],
      'activity_level_question': [activityLevel ?? ''],
      'health_conditions_question': healthConditions.toList(),
      'pain_mobility_question': painAreas.toList(),
      'exercise_preferences_question': exercisePreferences.toList(),
      'equipment_mobility_question': [
        ...equipment.map((e) => 'Equipment $e'),
        ...mobilityAids.map((m) => 'Mobility $m'),
      ],
      'hobbies_goals_question_hobbies': [hobbiesController.text],
      'hobbies_goals_question_short_goals': [shortGoalsController.text],
      'hobbies_goals_question_long_goals': [longGoalsController.text],
      'energy_level_question': [energyLevel ?? ''],
      'time_preference_question': [timePreference ?? ''],
      'wellness_goals_question': wellnessGoals.toList(),
      'extra_notes_question': [extraNotesController.text],
    };
  }

  Map<String, String> getQuestionsTextMap() {
    return {
      'personal_info_question_name': 'Personal Information (name)',
      'personal_info_question_age': 'Personal Information (age)',
      'personal_info_question_sex': 'Personal Information (sex)',
      'personal_info_question_height': 'Personal Information (height)',
      'personal_info_question_weight': 'Personal Information (weight)',
      'activity_level_question':
          'How often do you currently do physical activity?',
      'health_conditions_question':
          'Please select any health conditions you have (select all that apply)',
      'pain_mobility_question':
          'Do you experience any pain or discomfort when moving or exercising? Select all areas that apply',
      'exercise_preferences_question':
          'What types of exercise do you enjoy or would like to try? Select all that apply',
      'equipment_mobility_question': 'Equipment & Mobility Aids',
      'hobbies_goals_question_hobbies':
          'What are some of your favourite hobbies or interests?',
      'hobbies_goals_question_short_goals':
          'What are you looking forward to in the next 2-4 weeks?',
      'hobbies_goals_question_long_goals':
          'What are you looking forward to in the next 2-6 months?',
      'energy_level_question':
          'What energy level do you prefer for your workouts?',
      'time_preference_question':
          'What time of day do you prefer to exercise?',
      'wellness_goals_question':
          'What are your main wellness goals? Select all that apply',
      'extra_notes_question': 'Any extra notes or considerations?',
    };
  }

  @override
  void dispose() {
    pageController.dispose();
    for (final controller in _allControllers) {
      controller.removeListener(notifyListeners);
      controller.dispose();
    }
    super.dispose();
  }
}