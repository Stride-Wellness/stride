import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:stride_core/models/exercise_m.dart';
import 'dart:convert';

class ExerciseRepository {
  static const String _collection = 'exercises';
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Generate exercise plan using Cloud Function
  /// Returns list of generated exercises (2-3 exercises)
Future<List<ExerciseModel>> generateExercisePlan({
  required String userId,
  String? assessmentId,
  String? userRequests,
}) async {
  try {
    final callable = _functions.httpsCallable('generate_exercise_plan');

    print("here3");
    final result = await callable.call({
      'userId': userId,
      if (assessmentId != null) 'assessmentId': assessmentId,
      if (userRequests != null) 'userRequests': userRequests,
    });
    print("here4");
    
    final data = result.data as Map;
    final exercisesList = data['exercises'] as List;
    
    return exercisesList.map((e) {
      final jsonString = jsonEncode(e);
      final properMap = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Convert timestamp strings to Timestamp objects
      if (properMap['createdAt'] is String) {
        properMap['createdAt'] = Timestamp.fromDate(DateTime.parse(properMap['createdAt']));
      }
      if (properMap['updatedAt'] is String) {
        properMap['updatedAt'] = Timestamp.fromDate(DateTime.parse(properMap['updatedAt']));
      }
      
      return ExerciseModel.fromMap(properMap);
    }).toList();
  } catch (e) {
    print('generateExercisePlan: Error generating exercise plan: $e');
    throw Exception(
        'generateExercisePlan: Failed to generate exercise plan: $e');
  }
}
  /// Get exercise by ID
  Future<ExerciseModel?> getById(String exerciseId) async {
    try {
      final docSnap = await _db.collection(_collection).doc(exerciseId).get();

      if (!docSnap.exists) {
        return null;
      }

      return ExerciseModel.fromFirestore(docSnap);
    } catch (e) {
      print('Error getting exercise: $e');
      throw Exception('Failed to get exercise');
    }
  }

  /// Get exercises for a specific user
  /// By default, excludes completed exercises older than 30 days
  Future<List<ExerciseModel>> getByUserId({
    required String userId,
    bool includePast = true,
    int daysBack = 30,
  }) async {
    try {
      Query query = _db
          .collection(_collection)
          .where('createdFor', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      final querySnap = await query.get();
      final exercises = querySnap.docs
          .map((doc) => ExerciseModel.fromFirestore(doc))
          .toList();

      if (!includePast) {
        // Only return exercises that haven't been used yet
        return exercises.where((ex) => ex.usedAt.isEmpty).toList();
      }

      // Filter completed exercises to last 30 days
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
      return exercises.where((ex) {
        if (ex.usedAt.isEmpty) return true; // Include pending exercises
        // Include completed exercises within the last 30 days
        return ex.usedAt.any((date) => date.isAfter(cutoffDate));
      }).toList();
    } catch (e) {
      print('Error getting exercises by user: $e');
      throw Exception('Failed to get exercises');
    }
  }

  /// Mark exercise as completed (adds timestamp to usedAt array)
  Future<void> markAsCompleted(String exerciseId) async {
    try {
      await _db.collection(_collection).doc(exerciseId).update({
        'usedAt': FieldValue.arrayUnion([Timestamp.now()]),
      });
    } catch (e) {
      print('Error marking exercise as completed: $e');
      throw Exception('Failed to mark exercise as completed');
    }
  }

  /// Get pending exercises (not yet completed)
  Future<List<ExerciseModel>> getPendingExercises(String userId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('createdFor', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExerciseModel.fromFirestore(doc))
          .where((ex) => ex.usedAt.isEmpty)
          .toList();
    } catch (e) {
      print('Error getting pending exercises: $e');
      throw Exception('Failed to get pending exercises');
    }
  }

  /// Get completed exercises (last 30 days)
  Future<List<ExerciseModel>> getCompletedExercises(
    String userId, {
    int daysBack = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

      final snapshot = await _db
          .collection(_collection)
          .where('createdFor', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExerciseModel.fromFirestore(doc))
          .where((ex) {
        if (ex.usedAt.isEmpty) return false;
        return ex.usedAt.any((date) => date.isAfter(cutoffDate));
      }).toList();
    } catch (e) {
      print('Error getting completed exercises: $e');
      throw Exception('Failed to get completed exercises');
    }
  }

  Future<bool> deleteExercise(String exerciseId) async {
    try {
      await _db.collection(_collection).doc(exerciseId).delete();
      return true;
    } catch (e) {
      print('Error deleting exercise: $e');
      return false;
    }
  }
}
