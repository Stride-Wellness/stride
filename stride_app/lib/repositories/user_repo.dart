import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_app/models/user_m.dart';

class UserRepository {
  static const String _collection = 'users';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get user by ID
  Future<UserModel?> getById(String userId) async {
    try {
      final userRef = _db.collection(_collection).doc(userId);
      final userSnap = await userRef.get();

      if (!userSnap.exists) {
        return null;
      }

      final data = userSnap.data()!;
      return UserModel.fromMap(data, userSnap.id);
    } catch (error) {
      print('Error getting user: $error');
      throw Exception('Failed to get user');
    }
  }

  /// Get all users (admin only) - excludes deleted users by default
  Future<List<UserModel>> getAll({
    int limitCount = 100,
    bool includeDeleted = false,
  }) async {
    try {
      Query query = _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limitCount);

      // Filter out deleted users unless explicitly requested
      if (!includeDeleted) {
        query = _db
            .collection(_collection)
            .where('status', isNotEqualTo: 'deleted')
            .orderBy('createdAt', descending: true)
            .limit(limitCount);
      }

      final querySnap = await query.get();
      final users = <UserModel>[];

      for (final doc in querySnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        users.add(UserModel.fromMap(data, doc.id));
      }

      return users;
    } catch (error) {
      print('Error getting users: $error');
      throw Exception('Failed to get users');
    }
  }

  /// Get users by organization ID - excludes deleted users by default
  Future<List<UserModel>> getByOrganizationId(
    String organizationId, {
    bool includeDeleted = false,
  }) async {
    try {
      Query query = _db
          .collection(_collection)
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt', descending: true);

      // Filter out deleted users unless explicitly requested
      if (!includeDeleted) {
        query = _db
            .collection(_collection)
            .where('organizationId', isEqualTo: organizationId)
            .where('status', isNotEqualTo: 'deleted')
            .orderBy('createdAt', descending: true);
      }

      final querySnap = await query.get();
      final users = <UserModel>[];

      for (final doc in querySnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        users.add(UserModel.fromMap(data, doc.id));
      }

      return users;
    } catch (error) {
      print('Error getting users by organization: $error');
      throw Exception('Failed to get users by organization');
    }
  }

  /// Get users by division ID - excludes deleted users by default
  Future<List<UserModel>> getByDivisionId(
    String divisionId, {
    bool includeDeleted = false,
  }) async {
    try {
      Query query = _db
          .collection(_collection)
          .where('divisionId', isEqualTo: divisionId)
          .orderBy('createdAt', descending: true);

      // Filter out deleted users unless explicitly requested
      if (!includeDeleted) {
        query = _db
            .collection(_collection)
            .where('divisionId', isEqualTo: divisionId)
            .where('status', isNotEqualTo: 'deleted')
            .orderBy('createdAt', descending: true);
      }

      final querySnap = await query.get();
      final users = <UserModel>[];

      for (final doc in querySnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        users.add(UserModel.fromMap(data, doc.id));
      }

      return users;
    } catch (error) {
      print('Error getting users by division: $error');
      throw Exception('Failed to get users by division');
    }
  }

  /// Get users by type and organization - excludes deleted users by default
  Future<List<UserModel>> getByTypeAndOrganization(
    UserType type,
    String organizationId, {
    bool includeDeleted = false,
  }) async {
    try {
      Query query = _db
          .collection(_collection)
          .where('type', isEqualTo: type.name)
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt', descending: true);

      // Filter out deleted users unless explicitly requested
      if (!includeDeleted) {
        query = _db
            .collection(_collection)
            .where('type', isEqualTo: type.name)
            .where('organizationId', isEqualTo: organizationId)
            .where('status', isNotEqualTo: 'deleted')
            .orderBy('createdAt', descending: true);
      }

      final querySnap = await query.get();
      final users = <UserModel>[];

      for (final doc in querySnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        users.add(UserModel.fromMap(data, doc.id));
      }

      return users;
    } catch (error) {
      print('Error getting users by type and organization: $error');
      throw Exception('Failed to get users by type and organization');
    }
  }

  /// Get users by status and organization
  Future<List<UserModel>> getByStatusAndOrganization(
    UserStatus status,
    String organizationId,
  ) async {
    try {
      final query = _db
          .collection(_collection)
          .where('status', isEqualTo: status.name)
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt', descending: true);

      final querySnap = await query.get();
      final users = <UserModel>[];

      for (final doc in querySnap.docs) {
        final data = doc.data();
        users.add(UserModel.fromMap(data, doc.id));
      }

      return users;
    } catch (error) {
      print('Error getting users by status and organization: $error');
      throw Exception('Failed to get users by status and organization');
    }
  }

  /// Create new employee user
  /// Create new employee user with specific document ID (Firebase Auth UID)
  Future<EmployeeUserModel> createEmployee(
    CreateEmployeeUserDataModel data,
  ) async {
    try {
      final now = DateTime.now();
      final userData = {
        'email': data.email,
        'name': data.name,
        'type': 'employee',
        'employeeRole': data.employeeRole
            .map((e) => e.toString().split('.').last)
            .toList(),
        'organizationId': data.organizationId,
        'divisionId': data.divisionId,
        'profile': data.profile ?? {},
        'status': 'active',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      // Use the Firebase Auth UID as the document ID
      await _db.collection(_collection).doc(data.id).set(userData);

      return EmployeeUserModel(
        id: data.id,
        email: data.email,
        name: data.name,
        organizationId: data.organizationId,
        divisionId: data.divisionId,
        employeeRole: data.employeeRole,
        profile: data.profile ?? {},
        status: UserStatus.active,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      print('Error creating employee user: $e');
      throw Exception('Failed to create employee user');
    }
  }

  /// Create new client user
  Future<ClientUserModel> createClient(CreateClientUserDataModel data) async {
    try {
      final now = Timestamp.now();
      final userData = {
        'email': data.email,
        'name': data.name,
        'type': UserType.client.name,
        'organizationId': data.organizationId,
        'divisionId': data.divisionId,
        'profile': data.profile?.toMap() ?? {},
        'status': UserStatus.active.name,
        'createdAt': now,
        'updatedAt': now,
      };

      final docRef = await _db.collection(_collection).add(userData);

      return ClientUserModel(
        id: docRef.id,
        email: data.email,
        name: data.name,
        organizationId: data.organizationId,
        divisionId: data.divisionId,
        status: UserStatus.active,
        createdAt: now.toDate(),
        updatedAt: now.toDate(),
        profile: data.profile ?? ClientProfileModel(),
      );
    } catch (error) {
      print('Error creating client user: $error');
      throw Exception('Failed to create client user');
    }
  }

  /// Update employee user
  Future<void> updateEmployee(
    String userId,
    UpdateEmployeeUserDataModel data,
  ) async {
    try {
      final userRef = _db.collection(_collection).doc(userId);
      final updateData = data.toMap();
      updateData['updatedAt'] = Timestamp.now();

      await userRef.update(updateData);
    } catch (error) {
      print('Error updating employee user: $error');
      throw Exception('Failed to update employee user');
    }
  }

  /// Update client user
  Future<void> updateClient(
    String userId,
    UpdateClientUserDataModel data,
  ) async {
    try {
      final userRef = _db.collection(_collection).doc(userId);
      final updateData = data.toMap();
      updateData['updatedAt'] = Timestamp.now();

      await userRef.update(updateData);
    } catch (error) {
      print('Error updating client user: $error');
      throw Exception('Failed to update client user');
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      final userRef = _db.collection(_collection).doc(userId);
      await userRef.update({
        'lastLoginAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (error) {
      print('Error updating last login: $error');
      throw Exception('Failed to update last login');
    }
  }

  /// Soft delete user (set status to deleted and add deletedAt timestamp)
  Future<void> softDelete(String userId) async {
    try {
      await updateEmployee(
        userId,
        UpdateEmployeeUserDataModel(
          status: UserStatus.deleted,
          deletedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      print('Error soft deleting user: $error');
      throw Exception('Failed to delete user');
    }
  }

  /// Restore soft deleted user
  Future<void> restore(String userId) async {
    try {
      final userRef = _db.collection(_collection).doc(userId);
      await userRef.update({
        'status': UserStatus.active.name,
        'deletedAt': null,
        'updatedAt': Timestamp.now(),
      });
    } catch (error) {
      print('Error restoring user: $error');
      throw Exception('Failed to restore user');
    }
  }

  /// Check if user has any active assignments (to prevent hard delete)
  Future<bool> hasActiveAssignments(String userId) async {
    try {
      // This would need the AssignmentsService to be implemented
      // For now, return false to allow hard delete
      // TODO: Implement assignment checking once AssignmentsService is available
      print('Checking assignments for user: $userId');
      return false;
    } catch (error) {
      print('Error checking user assignments: $error');
      return true; // Err on the side of caution
    }
  }

  /// Hard delete user (use with caution) - only if no active references
  Future<void> hardDelete(String userId) async {
    try {
      // Check for active assignments before allowing hard delete
      final hasAssignments = await hasActiveAssignments(userId);
      if (hasAssignments) {
        throw Exception(
          'Cannot hard delete user with active assignments. Use soft delete instead.',
        );
      }

      final userRef = _db.collection(_collection).doc(userId);
      await userRef.delete();
    } catch (error) {
      print('Error hard deleting user: $error');
      throw Exception('Failed to permanently delete user');
    }
  }

  /// Check if user is employee
  bool isEmployee(UserModel user) {
    return user.isEmployee;
  }

  /// Check if user is client
  bool isClient(UserModel user) {
    return user.isClient;
  }

  /// Check if employee has specific role
  bool hasRole(UserModel user, EmployeeRole role) {
    final employee = user.asEmployee;
    if (employee == null) return false;
    return employee.employeeRole.contains(role);
  }

  /// Count active users by organization
  Future<int> countActiveByOrganization(String organizationId) async {
    try {
      final users = await getByStatusAndOrganization(
        UserStatus.active,
        organizationId,
      );
      return users.length;
    } catch (error) {
      print('Error counting active users: $error');
      return 0;
    }
  }
}
