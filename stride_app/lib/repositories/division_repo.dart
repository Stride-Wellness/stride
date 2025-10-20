import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_app/models/division_m.dart';

class DivisionRepository {
  static const String _collection = 'divisions';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get division by ID
  Future<DivisionModel?> getById(String divisionId) async {
    try {
      final docSnap = await _db.collection(_collection).doc(divisionId).get();

      if (!docSnap.exists) {
        return null;
      }

      return DivisionModel.fromFirestore(docSnap);
    } catch (e) {
      print('Error getting division: $e');
      throw Exception('Failed to get division');
    }
  }

  /// Get all divisions (admin only) - excludes deleted divisions by default
  Future<List<DivisionModel>> getAll({
    int limitCount = 100,
    bool includeDeleted = false,
  }) async {
    try {
      Query query = _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limitCount);

      // Filter out deleted divisions unless explicitly requested
      if (!includeDeleted) {
        query = query.where('status', isNotEqualTo: 'deleted');
      }

      final querySnap = await query.get();

      return querySnap.docs.map((doc) => DivisionModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting divisions: $e');
      throw Exception('Failed to get divisions');
    }
  }

  /// Get divisions by organization ID - excludes deleted divisions by default
  Future<List<DivisionModel>> getByOrganizationId(
    String organizationId, {
    bool includeDeleted = false,
  }) async {
    try {
      Query query = _db
          .collection(_collection)
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt', descending: true);

      // Filter out deleted divisions unless explicitly requested
      if (!includeDeleted) {
        query = query.where('status', isNotEqualTo: 'deleted');
      }

      final querySnap = await query.get();

      return querySnap.docs.map((doc) => DivisionModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting divisions by organization: $e');
      throw Exception('Failed to get divisions by organization');
    }
  }

  /// Create new division
  Future<DivisionModel> create(CreateDivisionDataModel data) async {
    try {
      final now = DateTime.now();
      final divisionData = {
        'organizationId': data.organizationId,
        'name': data.name,
        'managerId': data.managerId,
        'divisionType': data.divisionType,
        'settings': data.settings?.toMap() ?? {},
        'status': 'active',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _db.collection(_collection).add(divisionData);

      return DivisionModel(
        id: docRef.id,
        organizationId: data.organizationId,
        name: data.name,
        managerId: data.managerId,
        divisionType: data.divisionType,
        settings: data.settings ?? DivisionSettingsModel({}),
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      print('Error creating division: $e');
      throw Exception('Failed to create division');
    }
  }

  /// Update division
  Future<void> update(String divisionId, UpdateDivisionDataModel data) async {
    try {
      await _db.collection(_collection).doc(divisionId).update(data.toMap());
    } catch (e) {
      print('Error updating division: $e');
      throw Exception('Failed to update division');
    }
  }

  /// Assign a manager to a division
  Future<void> assignManager(String divisionId, String managerId) async {
    try {
      await update(divisionId, UpdateDivisionDataModel(managerId: managerId));
    } catch (e) {
      print('Error assigning manager to division: $e');
      throw Exception('Failed to assign manager to division');
    }
  }

  /// Soft delete division (set status to deleted and add deletedAt timestamp)
  Future<void> softDelete(String divisionId) async {
    try {
      await update(
        divisionId,
        UpdateDivisionDataModel(
          status: 'deleted',
          deletedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error soft deleting division: $e');
      throw Exception('Failed to delete division');
    }
  }

  /// Restore soft deleted division
  Future<void> restore(String divisionId) async {
    try {
      final divisionRef = _db.collection(_collection).doc(divisionId);
      await divisionRef.update({
        'status': 'active',
        'deletedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error restoring division: $e');
      throw Exception('Failed to restore division');
    }
  }

  /// Hard delete division (use with caution)
  Future<void> hardDelete(String divisionId) async {
    try {
      await _db.collection(_collection).doc(divisionId).delete();
    } catch (e) {
      print('Error hard deleting division: $e');
      throw Exception('Failed to permanently delete division');
    }
  }
}