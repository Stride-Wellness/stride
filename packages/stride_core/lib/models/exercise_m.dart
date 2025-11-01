import 'package:cloud_firestore/cloud_firestore.dart';

enum ExerciseType {
  physical,
  stretching,
  balance,
  strength,
  cardio,
  memory,      
  cognitive, 
  puzzle;     

  String toJson() => name;
  static ExerciseType fromJson(String value) =>
      ExerciseType.values.firstWhere((e) => e.name == value);
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced;

  String toJson() => name;
  static DifficultyLevel fromJson(String value) =>
      DifficultyLevel.values.firstWhere((e) => e.name == value);
}

class ExerciseInstructionModel {
  final int stepNumber;
  final String instruction;
  final String? imageUrl;

  ExerciseInstructionModel({
    required this.stepNumber,
    required this.instruction,
    this.imageUrl,
  });

  factory ExerciseInstructionModel.fromMap(Map<String, dynamic> map) {
    return ExerciseInstructionModel(
      stepNumber: map['stepNumber'] as int,
      instruction: map['instruction'] as String,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'instruction': instruction,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class ExerciseModificationModel {
  final String level; // e.g., "easier", "harder", "seated"
  final String description;

  ExerciseModificationModel({
    required this.level,
    required this.description,
  });

  factory ExerciseModificationModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModificationModel(
      level: map['level'] as String,
      description: map['description'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'description': description,
    };
  }
}

class ExerciseSafetyModel {
  final List<String> contraindications;
  final List<String> warnings;
  final List<String> tips;

  ExerciseSafetyModel({
    this.contraindications = const [],
    this.warnings = const [],
    this.tips = const [],
  });

  factory ExerciseSafetyModel.fromMap(Map<String, dynamic> map) {
    return ExerciseSafetyModel(
      contraindications: (map['contraindications'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      warnings: (map['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tips: (map['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contraindications': contraindications,
      'warnings': warnings,
      'tips': tips,
    };
  }
}

class ExerciseModel {
  final String id;
  final String createdFor;
  final String basedOff;
  final String title;
  final String description;
  final ExerciseType exerciseType;
  final DifficultyLevel difficulty;
  final int? durationMinutes;
  final int? repetitions;
  final int? sets;
  final int? restBetweenSetsSeconds;
  final List<ExerciseInstructionModel> instructions;
  final List<ExerciseModificationModel> modifications;
  final List<String> equipmentNeeded;
  final ExerciseSafetyModel? safety;
  final List<String> targetMuscles;
  final List<String> benefits;
  final DateTime createdAt;
  final List<DateTime> usedAt;
  final String? notes;

  ExerciseModel({
    required this.id,
    required this.createdFor,
    required this.basedOff,
    required this.title,
    required this.description,
    required this.exerciseType,
    required this.difficulty,
    this.durationMinutes,
    this.repetitions,
    this.sets,
    this.restBetweenSetsSeconds,
    this.instructions = const [],
    this.modifications = const [],
    this.equipmentNeeded = const [],
    this.safety,
    this.targetMuscles = const [],
    this.benefits = const [],
    required this.createdAt,
    this.usedAt = const [],
    this.notes,
  });

  bool get isCompleted => usedAt.isNotEmpty;
  bool get isPending => usedAt.isEmpty;

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseModel.fromMap({...data, 'id': doc.id});
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] as String,
      createdFor: map['createdFor'] as String,
      basedOff: map['basedOff'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      exerciseType: ExerciseType.fromJson(map['exerciseType'] as String),
      difficulty: DifficultyLevel.fromJson(map['difficulty'] as String),
      durationMinutes: map['durationMinutes'] as int?,
      repetitions: map['repetitions'] as int?,
      sets: map['sets'] as int?,
      restBetweenSetsSeconds: map['restBetweenSetsSeconds'] as int?,
      instructions: (map['instructions'] as List<dynamic>?)
              ?.map((e) =>
                  ExerciseInstructionModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      modifications: (map['modifications'] as List<dynamic>?)
              ?.map((e) =>
                  ExerciseModificationModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      equipmentNeeded: (map['equipmentNeeded'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      safety: map['safety'] != null
          ? ExerciseSafetyModel.fromMap(map['safety'] as Map<String, dynamic>)
          : null,
      targetMuscles: (map['targetMuscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      benefits: (map['benefits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      usedAt: (map['usedAt'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdFor': createdFor,
      'basedOff': basedOff,
      'title': title,
      'description': description,
      'exerciseType': exerciseType.toJson(),
      'difficulty': difficulty.toJson(),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (repetitions != null) 'repetitions': repetitions,
      if (sets != null) 'sets': sets,
      if (restBetweenSetsSeconds != null)
        'restBetweenSetsSeconds': restBetweenSetsSeconds,
      'instructions': instructions.map((e) => e.toMap()).toList(),
      'modifications': modifications.map((e) => e.toMap()).toList(),
      'equipmentNeeded': equipmentNeeded,
      if (safety != null) 'safety': safety!.toMap(),
      'targetMuscles': targetMuscles,
      'benefits': benefits,
      'createdAt': Timestamp.fromDate(createdAt),
      'usedAt': usedAt.map((e) => Timestamp.fromDate(e)).toList(),
      if (notes != null) 'notes': notes,
    };
  }
}
