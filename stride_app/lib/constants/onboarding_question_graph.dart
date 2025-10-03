
import 'package:stride_app/models/question_node_m.dart';

final questionGraph = {
  UserTypeQuestion.id: UserTypeQuestion(),
  ClientProfileQuestion.id: ClientProfileQuestion(),
  RelationshipQuestion.id: RelationshipQuestion(),
  PersonalInfoQuestion.id: PersonalInfoQuestion(),
  ActivityLevelQuestion.id: ActivityLevelQuestion(),
  HealthConditionsQuestion.id: HealthConditionsQuestion(),
  PainMobilityQuestion.id: PainMobilityQuestion(),
  ExercisePreferencesQuestion.id: ExercisePreferencesQuestion(),
  EquipmentMobilityQuestion.id: EquipmentMobilityQuestion(),
  GoalsInterestsQuestion.id: GoalsInterestsQuestion(),
  WellnessPreferencesQuestion.id: WellnessPreferencesQuestion(),
  SpecialNotesQuestion.id: SpecialNotesQuestion(),
};

// Step 1: User Type Selection
class UserTypeQuestion extends QuestionNode {
  static const String id = "user_type_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 1;

  @override
  String text(Map<String, List<String>> answers) {
    return "Who is using the platform today?";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("I am an older adult looking for personalized movement routines", QuestionType.select),
      QuestionOption("I am a caregiver helping someone with their wellness routine", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    bool isCaregiver = answers[questionId]?.contains("I am a caregiver helping someone with their wellness routine") ?? false;
    return isCaregiver ? ClientProfileQuestion.id : PersonalInfoQuestion.id;
  }
}

// Step 2: Client Profile (Caregiver Path Only)
class ClientProfileQuestion extends QuestionNode {
  static const String id = "client_profile_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 5;

  @override
  int get minSelected => 5;
  
  @override
  bool get isMultiField => true;
  
  @override
  List<String> get requiredFields => ['name', 'age', 'sex', 'height', 'weight'];

  @override
  String text(Map<String, List<String>> answers) {
    return "Client Profile";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("Client's Name", QuestionType.input, fieldKey: 'name'),
      QuestionOption("Client's Age", QuestionType.input, fieldKey: 'age'),
      QuestionOption("Client's Sex", QuestionType.dropdown, fieldKey: 'sex', 
        dropdownOptions: ["Male", "Female", "Prefer not to say"]),
      QuestionOption("Client's Height (in inches or cm)", QuestionType.input, fieldKey: 'height'),
      QuestionOption("Client's Weight (in pounds or kg)", QuestionType.input, fieldKey: 'weight'),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return requiredFields.every((field) => 
      getFieldValue(answers, field)?.isNotEmpty == true);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return RelationshipQuestion.id;
  }
}

class RelationshipQuestion extends QuestionNode {
  static const String id = "relationship_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 1;

  @override
  String text(Map<String, List<String>> answers) {
    return "Your Relationship to Client:";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("Family Member (Adult Child, Spouse, etc.)", QuestionType.select),
      QuestionOption("Personal Support Worker (PSW)", QuestionType.select),
      QuestionOption("Nurse or Healthcare Professional", QuestionType.select),
      QuestionOption("Physiotherapist", QuestionType.select),
      QuestionOption("Other", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return ((answers[questionId]?.length ?? 0) >= minSelected) &&
        ((answers[questionId]?.length ?? 0) <= maxSelected);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return PersonalInfoQuestion.id;
  }
}

// Step 3: Personal Information
class PersonalInfoQuestion extends QuestionNode {
  static const String id = "personal_info_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 5;

  @override
  int get minSelected => 3;
  
  @override
  bool get isMultiField => true;
  
  @override
  List<String> get requiredFields {
    // Base required fields
    List<String> fields = ['nickname', 'age', 'sex'];
    return fields;
  }

  @override
  String text(Map<String, List<String>> answers) {
    return "Personal Information";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    bool isOlderAdult = answers[UserTypeQuestion.id]?.contains("I am an older adult looking for personalized movement routines") ?? false;
    
    List<QuestionOption> baseOptions = [
      QuestionOption("Nickname (What would you like us to call you?)", QuestionType.input, fieldKey: 'nickname'),
      QuestionOption("Age", QuestionType.input, fieldKey: 'age'),
      QuestionOption("Sex", QuestionType.dropdown, fieldKey: 'sex',
        dropdownOptions: ["Male", "Female", "Prefer not to say"]),
    ];
    
    if (isOlderAdult) {
      baseOptions.addAll([
        QuestionOption("Height (in inches or cm)", QuestionType.input, fieldKey: 'height'),
        QuestionOption("Weight (in pounds or kg)", QuestionType.input, fieldKey: 'weight'),
      ]);
    }
    
    return baseOptions;
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    bool isOlderAdult = answers[UserTypeQuestion.id]?.contains("I am an older adult looking for personalized movement routines") ?? false;
    List<String> requiredForUser = ['nickname', 'age', 'sex'];
    if (isOlderAdult) {
      requiredForUser.addAll(['height', 'weight']);
    }
    return requiredForUser.every((field) => 
      getFieldValue(answers, field)?.isNotEmpty == true);
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return ActivityLevelQuestion.id;
  }
}

// Step 4: Current Activity Level
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
    bool isCaregiver = answers[UserTypeQuestion.id]?.contains("I am a caregiver helping someone with their wellness routine") ?? false;
    return isCaregiver 
        ? "How often does your client currently do physical activity?"
        : "How often do you currently do physical activity?";
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

// Step 5: Health Conditions
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
    bool isCaregiver = answers[UserTypeQuestion.id]?.contains("I am a caregiver helping someone with their wellness routine") ?? false;
    return isCaregiver 
        ? "Please select any health conditions your client has (select all that apply):"
        : "Please select any health conditions you have (select all that apply):";
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

// Step 6: Pain & Mobility Areas
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
    bool isCaregiver = answers[UserTypeQuestion.id]?.contains("I am a caregiver helping someone with their wellness routine") ?? false;
    return isCaregiver 
        ? "Does your client experience any pain or discomfort when moving or exercising? Select all areas that apply:"
        : "Do you experience any pain or discomfort when moving or exercising? Select all areas that apply:";
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

// Step 7: Exercise Preferences
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
    bool isCaregiver = answers[UserTypeQuestion.id]?.contains("I am a caregiver helping someone with their wellness routine") ?? false;
    return isCaregiver 
        ? "What types of exercise does your client enjoy or would like to try? Select all that apply:"
        : "What types of exercise do you enjoy or would like to try? Select all that apply:";
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

// Step 8: Equipment & Mobility
class EquipmentMobilityQuestion extends QuestionNode {
  static const String id = "equipment_mobility_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 9;

  @override
  int get minSelected => 2; // At least one from each category

  @override
  String text(Map<String, List<String>> answers) {
    return "Equipment & Mobility";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      // Equipment Available at Home
      QuestionOption("Equipment: Sturdy Chair", QuestionType.select),
      QuestionOption("Equipment: Resistance Bands", QuestionType.select),
      QuestionOption("Equipment: Light Weights (1-5 lbs)", QuestionType.select),
      QuestionOption("Equipment: Step or Stairs", QuestionType.select),
      QuestionOption("Equipment: None - I prefer no equipment workouts", QuestionType.select),
      // Mobility Aids Used
      QuestionOption("Mobility Aid: Wheelchair", QuestionType.select),
      QuestionOption("Mobility Aid: Walker", QuestionType.select),
      QuestionOption("Mobility Aid: Cane or Walking Stick", QuestionType.select),
      QuestionOption("Mobility Aid: None - No mobility aids needed", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    List<String> selectedAnswers = answers[questionId] ?? [];
    bool hasEquipment = selectedAnswers.any((answer) => answer.startsWith("Equipment:"));
    bool hasMobility = selectedAnswers.any((answer) => answer.startsWith("Mobility Aid:"));
    return hasEquipment && hasMobility;
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return GoalsInterestsQuestion.id;
  }
}

// Step 9: Goals & Interests
class GoalsInterestsQuestion extends QuestionNode {
  static const String id = "goals_interests_question";

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
    bool isCaregiver = answers[UserTypeQuestion.id]?.contains("I am a caregiver helping someone with their wellness routine") ?? false;
    return isCaregiver 
        ? "Goals & Interests for Your Client"
        : "Your Goals & Interests";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    bool isCaregiver = answers[UserTypeQuestion.id]?.contains("I am a caregiver helping someone with their wellness routine") ?? false;
    return [
      QuestionOption(isCaregiver ? "Your client's favourite hobbies or interests" : "Your favourite hobbies or interests", 
        QuestionType.input, fieldKey: 'hobbies'),
      QuestionOption(isCaregiver ? "What are they looking forward to in the next 2-4 weeks?" : "What are you looking forward to in the next 2-4 weeks?", 
        QuestionType.input, fieldKey: 'short_goals'),
      QuestionOption(isCaregiver ? "What are they looking forward to in the next 2-6 months?" : "What are you looking forward to in the next 2-6 months?", 
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
    return WellnessPreferencesQuestion.id;
  }
}

// Step 10: Wellness Preferences
class WellnessPreferencesQuestion extends QuestionNode {
  static const String id = "wellness_preferences_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 7; // 1 energy + 1 time + up to 3 wellness goals + 2 extra buffer

  @override
  int get minSelected => 3; // 1 energy + 1 time + at least 1 wellness goal

  @override
  String text(Map<String, List<String>> answers) {
    return "Wellness Preferences";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      // Energy Level Preference
      QuestionOption("Energy: Low - I prefer gentle movements", QuestionType.select),
      QuestionOption("Energy: Moderate - I can handle some challenge", QuestionType.select),
      QuestionOption("Energy: High - I want to push myself", QuestionType.select),
      // Preferred Time of Day
      QuestionOption("Time: Morning", QuestionType.select),
      QuestionOption("Time: Afternoon", QuestionType.select),
      QuestionOption("Time: Evening", QuestionType.select),
      // Main Wellness Goals
      QuestionOption("Goal: Joint Mobility - Improve flexibility and range of motion", QuestionType.select),
      QuestionOption("Goal: Balance - Improve stability and prevent falls", QuestionType.select),
      QuestionOption("Goal: Cognition - Improve mental sharpness and coordination", QuestionType.select),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    List<String> selectedAnswers = answers[questionId] ?? [];
    bool hasEnergy = selectedAnswers.any((answer) => answer.startsWith("Energy:"));
    bool hasTime = selectedAnswers.any((answer) => answer.startsWith("Time:"));
    bool hasGoal = selectedAnswers.any((answer) => answer.startsWith("Goal:"));
    return hasEnergy && hasTime && hasGoal;
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return SpecialNotesQuestion.id;
  }
}

class SpecialNotesQuestion extends QuestionNode {
  static const String id = "special_notes_question";

  @override
  String get questionId => id;

  @override
  int get maxSelected => 1;

  @override
  int get minSelected => 0;

  @override
  String text(Map<String, List<String>> answers) {
    return "Special Notes & Considerations:\n\nPlease provide any additional information about safety considerations, concerns, or preferences:";
  }

  @override
  List<QuestionOption> options(Map<String, List<String>> answers) {
    return [
      QuestionOption("Additional notes", QuestionType.input),
    ];
  }

  @override
  bool answered(Map<String, List<String>> answers) {
    return true; // This is optional
  }

  @override
  String? getNextId(Map<String, List<String>> answers) {
    return null; // End of graph
  }
}