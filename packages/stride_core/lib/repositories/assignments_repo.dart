import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/services/auth_service.dart';

class AssignmentsRepository {
  static const String _collection = 'assignments';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService;

  AssignmentsRepository({required AuthService authService})
      : _authService = authService;

  /// Get clients assigned to a specific provider
  Future<List<ClientUserModel>> getClients_(String providerId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('workerId', isEqualTo: providerId)
          .where('status', isEqualTo: 'active')
          .get();

      final List<ClientUserModel> clients = [];
      
      for (var doc in snapshot.docs) {
        final clientId = doc.data()['clientId'] as String;
        final clientDoc = await _db.collection('users').doc(clientId).get();

        if (clientDoc.exists) {
          final userData = clientDoc.data()!;
          final user = UserModel.fromMap(userData, clientDoc.id);

          if (user.isClient) {
            clients.add(user.asClient!);
          }
        }
      }

      return clients;
    } catch (e) {
      print('Error getting clients by provider: $e');
      throw Exception('Failed to get clients');
    }
  }

  /// Get clients assigned to the current authenticated provider
  Future<List<ClientUserModel>> getClients() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return getClients_(userId);
  }

  /// Get provider assigned to a specific client
  Future<ProviderUserModel?> getProvider_(String clientId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final providerId = snapshot.docs.first.data()['workerId'] as String;
      final providerDoc = await _db.collection('users').doc(providerId).get();

      if (!providerDoc.exists) {
        return null;
      }

      final userData = providerDoc.data()!;
      final user = UserModel.fromMap(userData, providerDoc.id);

      return user.isProvider ? user.asEmployee : null;
    } catch (e) {
      print('Error getting provider by client: $e');
      throw Exception('Failed to get provider');
    }
  }

  /// Get provider assigned to the current authenticated client
  Future<ProviderUserModel?> getProvider() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return getProvider_(userId);
  }

  /// Assign a client to a provider
  Future<void> assignClientToProvider_({
    required String clientId,
    required String providerId,
    required String divisionId,
  }) async {
    try {
      final assignedBy = _authService.currentUser?.uid;
      if (assignedBy == null) {
        throw Exception('User not authenticated');
      }

      final now = Timestamp.now();
      
      await _db.collection(_collection).add({
        'clientId': clientId,
        'workerId': providerId,
        'divisionId': divisionId,
        'assignedBy': assignedBy,
        'status': 'active',
        'assignedAt': now,
        'createdAt': now,
        'updatedAt': now,
      });
    } catch (e) {
      print('Error assigning client to provider: $e');
      throw Exception('Failed to assign client to provider');
    }
  }

  /// Remove assignment between client and provider
  Future<void> removeAssignment_({
    required String clientId,
    required String providerId,
  }) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .where('workerId', isEqualTo: providerId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error removing assignment: $e');
      throw Exception('Failed to remove assignment');
    }
  }

  /// Check if current user has any assignments
  Future<bool> hasAssignments() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return false;
    }

    try {
      // Check as provider
      final providerQuery = await _db
          .collection(_collection)
          .where('workerId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (providerQuery.docs.isNotEmpty) {
        return true;
      }

      // Check as client
      final clientQuery = await _db
          .collection(_collection)
          .where('clientId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      return clientQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking assignments: $e');
      return false;
    }
  }
}