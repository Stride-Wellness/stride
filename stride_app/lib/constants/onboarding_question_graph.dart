import 'package:stride_app/models/question_node_m.dart';

final questionGraph = {
  PersonalInfoQuestion.id: PersonalInfoQuestion(),
  ActivityLevelQuestion.id: ActivityLevelQuestion(),
  HealthConditionsQuestion.id: HealthConditionsQuestion(),
  PainMobilityQuestion.id: PainMobilityQuestion(),
  ExercisePreferencesQuestion.id: ExercisePreferencesQuestion(),
  EquipmentMobilityQuestion.id: EquipmentMobilityQuestion(),
  HobbiesGoalsQuestion.id: HobbiesGoalsQuestion(),
  EnergyLevelQuestion.id: EnergyLevelQuestion(),
  TimePreferenceQuestion.id: TimePreferenceQuestion(),
  WellnessGoalsQuestion.id: WellnessGoalsQuestion(),
  EmailPasswordQuestion.id: EmailPasswordQuestion(),
};

// Step 1: Personal Information
class PersonalInfoQuestion extends QuestionNode {
  static const String id = "personal_info_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 5;

  @override
  int get minSelected => 5;
  
  @override
  bool get isMultiField => true;
  
  @override
  List<String> get requiredFields => [
    'name',
    'age',
    'sex',
    'height',
    'weight',
  ];

  @override
  String text(Map<String, List<String>> answers) {
    return "Personal Information";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption(
        "Name (What would you like us to call you?)",
        QuestionType.input,
        fieldKey: 'name',
      ),
      QuestionOption("Age", QuestionType.input, fieldKey: 'age'),
      QuestionOption("Sex", QuestionType.dropdown, fieldKey: 'sex',
        dropdownOptions: ["Male", "Female", "Prefer not to say"],
      ),
      QuestionOption(
        "Height (in inches or cm)",
        QuestionType.input,
        fieldKey: 'height',
      ),
      QuestionOption(
        "Weight (in pounds or kg)",
        QuestionType.input,
        fieldKey: 'weight',
      ),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return requiredFields.every(
      (field) => 
      getFieldValue(answers, field)?.isNotEmpty == true);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return ActivityLevelQuestion.id;
  }
}

// Step 2: Activity Level
class ActivityLevelQuestion extends QuestionNode {
  static const String id = "activity_level_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 1;

  @override
  String text(Map<String, List<String>> answers) {
    return "How often do you currently do physical activity?";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("Rarely or Never", QuestionType.select),
      QuestionOption("1–2 times per week", QuestionType.select),
      QuestionOption("3+ times per week", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return HealthConditionsQuestion.id;
  }
}

// Step 3: Health Conditions
class HealthConditionsQuestion extends QuestionNode {
  static const String id = "health_conditions_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 9;

  @override
  int get minSelected => 1;

  @override
  String text(Map<String, List<String>> answers) {
    return "Please select any health conditions you have (select all that apply)";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("None of the above", QuestionType.select),
      QuestionOption("Diabetes", QuestionType.select),
      QuestionOption("Heart Disease", QuestionType.select),
      QuestionOption("High Blood Pressure", QuestionType.select),
      QuestionOption("Osteoporosis", QuestionType.select),
      QuestionOption("Arthritis", QuestionType.select),
      QuestionOption("Parkinson's Disease", QuestionType.select),
      QuestionOption("Stroke", QuestionType.select),
      QuestionOption("Dementia", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return PainMobilityQuestion.id;
  }
}

// Step 4: Pain & Mobility Areas
class PainMobilityQuestion extends QuestionNode {
  static const String id = "pain_mobility_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 8;

  @override
  int get minSelected => 1;

  @override
  String text(Map<String, List<String>> answers) {
    return "Do you experience any pain or discomfort when moving or exercising? Select all areas that apply";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("No pain or discomfort", QuestionType.select),
      QuestionOption("Knees", QuestionType.select),
      QuestionOption("Hips", QuestionType.select),
      QuestionOption("Back", QuestionType.select),
      QuestionOption("Shoulders", QuestionType.select),
      QuestionOption("Neck", QuestionType.select),
      QuestionOption("Balance Problems", QuestionType.select),
      QuestionOption("History of Falls", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return ExercisePreferencesQuestion.id;
  }
}

// Step 5: Exercise Preferences
class ExercisePreferencesQuestion extends QuestionNode {
  static const String id = "exercise_preferences_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 8;

  @override
  int get minSelected => 1;

  @override
  String text(Map<String, List<String>> answers) {
    return "What types of exercise do you enjoy or would like to try? Select all that apply";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("Walking", QuestionType.select),
      QuestionOption("Stretching", QuestionType.select),
      QuestionOption("Tai Chi", QuestionType.select),
      QuestionOption("Strengthening", QuestionType.select),
      QuestionOption("Cardio", QuestionType.select),
      QuestionOption("Balance", QuestionType.select),
      QuestionOption("Dancing", QuestionType.select),
      QuestionOption("Seated Workouts", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return EquipmentMobilityQuestion.id;
  }
}

// Step 6: Equipment & Mobility Aids
class EquipmentMobilityQuestion extends QuestionNode {
  static const String id = "equipment_mobility_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 9;

  @override
  int get minSelected => 2; // At least 1 equipment + 1 mobility

  @override
  String text(Map<String, List<String>> answers) {
    return "Equipment & Mobility Aids";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      // Equipment Available at Home
      QuestionOption("Equipment Sturdy Chair", QuestionType.select),
      QuestionOption("Equipment Resistance Bands", QuestionType.select),
      QuestionOption("Equipment Light Weights (1-5 lbs)", QuestionType.select),
      QuestionOption("Equipment Step or Stairs", QuestionType.select),
      QuestionOption(
        "Equipment None - I prefer no equipment workouts",
        QuestionType.select,
      ),
      // Mobility Aids Used
      QuestionOption("Mobility Wheelchair", QuestionType.select),
      QuestionOption("Mobility Walker", QuestionType.select),
      QuestionOption("Mobility Cane or Walking Stick", QuestionType.select),
      QuestionOption(
        "Mobility None - No mobility aids needed",
        QuestionType.select,
      ),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    List<String> selectedAnswers = answers[questionId] ?? [];
    bool hasEquipment = selectedAnswers.any(
      (answer) => answer.startsWith("Equipment"),
    );
    bool hasMobility = selectedAnswers.any(
      (answer) => answer.startsWith("Mobility"),
    );
    return hasEquipment && hasMobility;
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return HobbiesGoalsQuestion.id;
  }
}

// Step 7: Hobbies & Goals
class HobbiesGoalsQuestion extends QuestionNode {
  static const String id = "hobbies_goals_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 3;

  @override
  int get minSelected => 3;
  
  @override
  bool get isMultiField => true;
  
  @override
  List<String> get requiredFields => ['hobbies', 'short_goals', 'long_goals'];

  @override
  String text(Map<String, List<String>> answers) {
    return "Hobbies & Goals";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption(
        "What are some of your favourite hobbies or interests?", 
        QuestionType.input, fieldKey: 'hobbies'),
      QuestionOption(
        "What are you looking forward to in the next 2-4 weeks?", 
        QuestionType.input, fieldKey: 'short_goals'),
      QuestionOption(
        "What are you looking forward to in the next 2-6 months?", 
        QuestionType.input, fieldKey: 'long_goals'),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return requiredFields.every((field) => 
      getFieldValue(answers, field)?.isNotEmpty == true);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return EnergyLevelQuestion.id;
  }
}

// Step 8: Energy Level Preference
class EnergyLevelQuestion extends QuestionNode {
  static const String id = "energy_level_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 1;

  @override
  bool get isMultiField => false;

  @override
  List<String> get requiredFields => [];

  @override
  String text(Map<String, List<String>> answers) {
    return "What energy level do you prefer for your workouts?";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("Low - I prefer gentle movements", QuestionType.select),
      QuestionOption(
        "Moderate - I can handle some challenge",
        QuestionType.select,
      ),
      QuestionOption("High - I want to push myself", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return TimePreferenceQuestion.id;
  }
}

// Step 9: Time Preference
class TimePreferenceQuestion extends QuestionNode {
  static const String id = "time_preference_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 1;

  @override
  bool get isMultiField => false;

  @override
  List<String> get requiredFields => [];

  @override
  String text(Map<String, List<String>> answers) {
    return "What time of day do you prefer to exercise?";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("Morning", QuestionType.select),
      QuestionOption("Afternoon", QuestionType.select),
      QuestionOption("Evening", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return WellnessGoalsQuestion.id;
  }
}

// Step 10: Wellness Goals & Special Notes
class WellnessGoalsQuestion extends QuestionNode {
  static const String id = "wellness_goals_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 4; // 3 goals + 1 special notes

  @override
  int get minSelected => 1; // At least 1 goal

  @override
  bool get isMultiField => false;

  @override
  List<String> get requiredFields => [];

  @override
  String text(Map<String, List<String>> answers) {
    return "What are your main wellness goals? Select all that apply";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption(
        "Joint Mobility - Improve flexibility and range of motion",
        QuestionType.select,
      ),
      QuestionOption(
        "Balance - Improve stability and prevent falls",
        QuestionType.select,
      ),
      QuestionOption(
        "Cognition - Improve mental sharpness and coordination",
        QuestionType.select,
      ),
      QuestionOption(
        "Special notes & considerations (optional)",
        QuestionType.input,
        fieldKey: 'special_notes',
      ),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    List<String> selectedAnswers = answers[questionId] ?? [];
    // Must have at least one goal selected (not counting the optional special notes)
    bool hasGoal = selectedAnswers.any(
      (answer) =>
          answer.startsWith("Joint Mobility") ||
          answer.startsWith("Balance") ||
          answer.startsWith("Cognition"),
    );

    return hasGoal;
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return EmailPasswordQuestion.id;
  }
}

// Step 11: Email & Password
class EmailPasswordQuestion extends QuestionNode {
  static const String id = "email_password_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 2;

  @override
  int get minSelected => 2;

  @override
  bool get isMultiField => true;

  @override
  List<String> get requiredFields => ['email', 'password'];

  @override
  String text(Map<String, List<String>> answers) {
    return "Create your account";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("Email Address", QuestionType.input, fieldKey: 'email'),
      QuestionOption("Password", QuestionType.input, fieldKey: 'password'),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return requiredFields.every(
      (field) => getFieldValue(answers, field)?.isNotEmpty == true,
    );
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return null; // End of onboarding
  }
}