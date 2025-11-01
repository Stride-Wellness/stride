import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/models/exercise_m.dart';
import 'package:stride_core/repositories/exercise_repo.dart';

get exerciseVMP => ChangeNotifierProvider(
    create: (context) => ExerciseVM(
      exerciseRepo: context.read<ExerciseRepository>(),
      authController: context.read<AuthStateController>(),
    ),
  );

enum ExerciseViewState {
  idle,
  loading,
  generating,
  error,
}

class ExerciseVM extends ChangeNotifier {
  final ExerciseRepository _exerciseRepo;
  final AuthStateController _authController;

  ExerciseVM({
    required ExerciseRepository exerciseRepo,
    required AuthStateController authController,
  })  : _exerciseRepo = exerciseRepo,
        _authController = authController;

  // State
  ExerciseViewState _state = ExerciseViewState.idle;
  String? _errorMessage;
  
  // Generated exercises waiting for selection
  List<ExerciseModel> _generatedExercises = [];
  
  // Pending (selected but not completed)
  List<ExerciseModel> _pendingExercises = [];
  
  // Completed (last 30 days)
  List<ExerciseModel> _completedExercises = [];

  // Getters
  ExerciseViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<ExerciseModel> get generatedExercises => _generatedExercises;
  List<ExerciseModel> get pendingExercises => _pendingExercises;
  List<ExerciseModel> get completedExercises => _completedExercises;
  
  bool get isLoading =>
      _state == ExerciseViewState.loading ||
      _state == ExerciseViewState.generating;
  bool get hasError => _state == ExerciseViewState.error;
  bool get hasGeneratedExercises => _generatedExercises.isNotEmpty;

  /// Initialize - load pending and completed exercises
  Future<void> initialize() async {
    await loadExercises();
  }

  /// Load all exercises for the user
  Future<void> loadExercises() async {
    try {
      _setState(ExerciseViewState.loading);
      _errorMessage = null;

      // Load pending exercises
      _pendingExercises = await _exerciseRepo.getPendingExercises(_authController.user!.id);

      // Load completed exercises (last 30 days)
      _completedExercises = await _exerciseRepo.getCompletedExercises(_authController.user!.id);

      _setState(ExerciseViewState.idle);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ExerciseViewState.error);
      rethrow;
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    final success = await _exerciseRepo.deleteExercise(exerciseId);
    if (success) {
      await loadExercises();
    } else {
      _errorMessage = 'Failed to delete exercise';
      _setState(ExerciseViewState.error);
    }
  }

  /// Generate new exercises (2-3) using AI
  Future<void> generateExercises({
    String? assessmentId,
    String? userRequests,
  }) async {
    // try 
    {
      _setState(ExerciseViewState.generating);
      _errorMessage = null;

      final exercises = await _exerciseRepo.generateExercisePlan(
        userId: _authController.user!.id,
        assessmentId: assessmentId,
        userRequests: userRequests,
      );

      print("here1");
      _generatedExercises = exercises;
      print("here2");
      _setState(ExerciseViewState.idle);
    } 
    //catch (e) {
    //   _errorMessage = e.toString();
    //   _setState(ExerciseViewState.error);
    //   rethrow;
    // }
  }

  /// Select an exercise from generated list (moves to pending)
  Future<void> selectExercise(ExerciseModel exercise) async {
    // Remove from generated list
    _generatedExercises.remove(exercise);
    
    // Add to pending list
    _pendingExercises.insert(0, exercise);
    
    notifyListeners();
  }

  /// Discard generated exercises (they remain in Firestore but ignored)
  void discardGeneratedExercises() {
    _generatedExercises.clear();
    notifyListeners();
  }

  /// Mark exercise as completed
  Future<void> completeExercise(ExerciseModel exercise) async {
    try {
      await _exerciseRepo.markAsCompleted(exercise.id);

      // Update local state
      _pendingExercises.removeWhere((ex) => ex.id == exercise.id);
      
      // Add to completed with updated usedAt
      final updatedExercise = ExerciseModel(
        id: exercise.id,
        createdFor: exercise.createdFor,
        basedOff: exercise.basedOff,
        title: exercise.title,
        description: exercise.description,
        exerciseType: exercise.exerciseType,
        difficulty: exercise.difficulty,
        durationMinutes: exercise.durationMinutes,
        repetitions: exercise.repetitions,
        sets: exercise.sets,
        restBetweenSetsSeconds: exercise.restBetweenSetsSeconds,
        instructions: exercise.instructions,
        modifications: exercise.modifications,
        equipmentNeeded: exercise.equipmentNeeded,
        safety: exercise.safety,
        targetMuscles: exercise.targetMuscles,
        benefits: exercise.benefits,
        createdAt: exercise.createdAt,
        usedAt: [...exercise.usedAt, DateTime.now()],
        notes: exercise.notes,
      );
      
      _completedExercises.insert(0, updatedExercise);
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  void _setState(ExerciseViewState newState) {
    _state = newState;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _setState(ExerciseViewState.idle);
  }
}
