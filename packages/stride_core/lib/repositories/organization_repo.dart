import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_core/models/organization_m.dart';

class OrganizationRepository {
  static const String _collection = 'organizations';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get organization by ID
  Future<OrganizationModel?> getById(String organizationId) async {
    try {
      final docSnap = await _db.collection(_collection).doc(organizationId).get();

      if (!docSnap.exists) {
        return null;
      }

      return OrganizationModel.fromFirestore(docSnap);
    } catch (e) {
      print('Error getting organization: $e');
      throw Exception('Failed to get organization');
    }
  }

  /// Get all organizations (admin only)
  Future<List<OrganizationModel>> getAll({int limitCount = 100}) async {
    try {
      final querySnap = await _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limitCount)
          .get();

      return querySnap.docs.map((doc) => OrganizationModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting organizations: $e');
      throw Exception('Failed to get organizations');
    }
  }

  /// Get organizations by status
  Future<List<OrganizationModel>> getByStatus(String status) async {
    try {
      final querySnap = await _db
          .collection(_collection)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnap.docs.map((doc) => OrganizationModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting organizations by status: $e');
      throw Exception('Failed to get organizations by status');
    }
  }

  /// Create new organization
  Future<OrganizationModel> create(CreateOrganizationDataModel data) async {
    try {
      final now = DateTime.now();
      final orgData = {
        'name': data.name,
        'totalSeats': data.totalSeats,
        'usedSeats': 0,
        'status': 'active',
        'stripeUserId': data.stripeUserId,
        'settings': data.settings?.toMap() ?? {},
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _db.collection(_collection).add(orgData);

      return OrganizationModel(
        id: docRef.id,
        name: data.name,
        totalSeats: data.totalSeats,
        usedSeats: 0,
        status: 'active',
        stripeUserId: data.stripeUserId,
        settings: data.settings ?? OrganizationSettingsModel({}),
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      print('Error creating organization: $e');
      throw Exception('Failed to create organization');
    }
  }

  /// Update organization
  Future<void> update(String organizationId, UpdateOrganizationDataModel data) async {
    try {
      await _db.collection(_collection).doc(organizationId).update(data.toMap());
    } catch (e) {
      print('Error updating organization: $e');
      throw Exception('Failed to update organization');
    }
  }

  /// Update seat usage (called when users are added/removed)
  Future<void> updateSeatUsage(String organizationId, int usedSeats) async {
    try {
      await _db.collection(_collection).doc(organizationId).update({
        'usedSeats': usedSeats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating seat usage: $e');
      throw Exception('Failed to update seat usage');
    }
  }

  /// Delete organization (soft delete by setting status to cancelled)
  Future<void> softDelete(String organizationId) async {
    try {
      await update(organizationId, UpdateOrganizationDataModel(status: 'cancelled'));
    } catch (e) {
      print('Error soft deleting organization: $e');
      throw Exception('Failed to delete organization');
    }
  }

  /// Hard delete organization (use with caution)
  Future<void> hardDelete(String organizationId) async {
    try {
      await _db.collection(_collection).doc(organizationId).delete();
    } catch (e) {
      print('Error hard deleting organization: $e');
      throw Exception('Failed to permanently delete organization');
    }
  }

  /// Check if organization has available seats
  Future<bool> hasAvailableSeats(String organizationId) async {
    try {
      final org = await getById(organizationId);
      if (org == null) return false;

      return org.usedSeats < org.totalSeats;
    } catch (e) {
      print('Error checking available seats: $e');
      return false;
    }
  }

  /// Get seat utilization percentage
  Future<int> getSeatUtilization(String organizationId) async {
    try {
      final org = await getById(organizationId);
      if (org == null || org.totalSeats == 0) return 0;

      return ((org.usedSeats / org.totalSeats) * 100).round();
    } catch (e) {
      print('Error calculating seat utilization: $e');
      return 0;
    }
  }
}