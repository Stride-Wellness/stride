import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/models/quiz_result_m.dart';
import 'package:stride_core/services/auth_service.dart';

class UserRepository {
  static const String _collection = 'users';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService;
  final FirebaseFunctions _functions;

  UserRepository({required AuthService authService, FirebaseFunctions? functions})
      : _authService = authService,
        _functions = functions ?? FirebaseFunctions.instance;

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    final callable = _functions.httpsCallable(name);
    final result = await callable.call(data);
    final raw = result.data;
    if (raw is! Map) {
      throw Exception('Unexpected response from $name');
    }
    return Map<String, dynamic>.from(raw as Map);
  }

  UserModel _parseUser(dynamic rawUser) {
    final userMap = Map<String, dynamic>.from(rawUser as Map);
    final id = userMap['id'] as String? ?? '';
    return UserModel.fromMap(userMap, id);
  }

  /// Save onboarding quiz result under user's subcollection
  Future<void> saveQuizResult_({
    required String userId,
    required Map<String, dynamic> answers,
    required Map<String, String> questions,
    required String name,
  }) async {
    try {
      final quizResult = QuizResult(
        id: '', // Firestore will auto-generate
        name: name,
        questions: questions,
        answers: answers,
        userId: userId,
        timestamp: Timestamp.now(),
      );
      final userRef = UserRepository._db
          .collection(UserRepository._collection)
          .doc(userId);
      await userRef.collection('quiz_results').add(quizResult.toMap());
    } catch (e) {
      print('Error saving onboarding quiz result: $e');
      throw Exception('Failed to save onboarding quiz result');
    }
  }

  /// Save quiz result for currently authenticated user
  Future<void> saveQuizResult({
    required Map<String, dynamic> answers,
    required Map<String, String> questions,
    String name = 'onboarding',
  }) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated to save quiz results');
    }
    return saveQuizResult_(
        userId: userId, answers: answers, questions: questions, name: name);
  }


  Future<List<QuizResult>> getQuizzes() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated to get quiz results');
    }

    final userRef =
        UserRepository._db.collection(UserRepository._collection).doc(userId);
    final quizResultsSnap = await userRef.collection('quiz_results').get();

    return quizResultsSnap.docs.map((doc) {
      final data = doc.data();
      return QuizResult.fromMap(data, doc.id);
    }).toList();
  }

  /// Get user by ID
  Future<UserModel?> get_(String userId) async {
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

  /// Get currently authenticated user
  Future<UserModel?> get() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return null;
    }
    return get_(userId);
  }



  /// Get users by organization ID
  Future<List<UserModel>> getByOrganization() async {
    final organizationId = (await get())?.organizationId;
    if (organizationId == null) {
      return [];
    }

    try {
      final querySnap = await _db
          .collection(_collection)
          .where('organizationId', isEqualTo: organizationId)
          .get();

      return querySnap.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting users by organization: $e');
      throw Exception('Failed to get users by organization');
    }
  }

  /// Admin-facing Cloud Function accessors
  Future<List<UserModel>> getUsersViaFunctions({
    int limitCount = 100,
    bool includeDeleted = false,
    List<String>? userIds,
    String? organizationId,
    String? divisionId,
    UserType? userType,
    UserStatus? status,
  }) async {
    final response = await _callFunction('get_users', {
      'limit': limitCount,
      'includeDeleted': includeDeleted,
      if (userIds != null) 'userIds': userIds,
      if (organizationId != null) 'organizationId': organizationId,
      if (divisionId != null) 'divisionId': divisionId,
      if (userType != null) 'userType': userType.name,
      if (status != null) 'status': status.name,
    });

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to get users');
    }

    return (response['users'] as List<dynamic>? ?? [])
        .map((user) => _parseUser(user))
        .toList();
  }

  Future<UserModel?> getUserByIdViaFunctions(String userId) async {
    final response = await _callFunction('get_user_by_id', {'userId': userId});
    if (!(response['success'] as bool? ?? false)) {
      return null;
    }
    return _parseUser(response['user']);
  }

  Future<List<UserModel>> getUsersByIdsViaFunctions(List<String> userIds) async {
    if (userIds.length > 10) {
      throw Exception('Cannot get more than 10 users by ID at once');
    }

    return getUsersViaFunctions(userIds: userIds);
  }

  Future<List<UserModel>> getUsersByOrganizationViaFunctions(
    String organizationId, {
    bool includeDeleted = false,
  }) async {
    return getUsersViaFunctions(
      organizationId: organizationId,
      includeDeleted: includeDeleted,
      limitCount: 1000,
    );
  }

  Future<List<UserModel>> getUsersByDivisionViaFunctions(
    String divisionId, {
    bool includeDeleted = false,
  }) async {
    return getUsersViaFunctions(
      divisionId: divisionId,
      includeDeleted: includeDeleted,
      limitCount: 1000,
    );
  }

  Future<List<UserModel>> getUsersByTypeAndOrganizationViaFunctions(
    UserType type,
    String organizationId, {
    bool includeDeleted = false,
  }) async {
    return getUsersViaFunctions(
      organizationId: organizationId,
      userType: type,
      includeDeleted: includeDeleted,
      limitCount: 1000,
    );
  }

  Future<List<UserModel>> getUsersByStatusAndOrganizationViaFunctions(
    UserStatus status,
    String organizationId,
  ) async {
    return getUsersViaFunctions(
      organizationId: organizationId,
      status: status,
      limitCount: 1000,
    );
  }

  Future<Map<String, int>> getUserStats({String? organizationId}) async {
    final response = await _callFunction('get_user_stats', {
      if (organizationId != null) 'organizationId': organizationId,
    });

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to get user statistics');
    }

    final statsRaw = Map<String, dynamic>.from(response['stats'] ?? {});
    return statsRaw.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
  }

  Future<String> createProviderViaFunctions({
    required String email,
    required String password,
    required String name,
    required String organizationId,
    required String divisionId,
    required List<ProviderRole> providerRole,
  }) async {
    final response = await _callFunction('create_provider', {
      'email': email,
      'password': password,
      'name': name,
      'organizationId': organizationId,
      'divisionId': divisionId,
      'providerRole': providerRole.map((e) => e.name).toList(),
    });

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to create provider');
    }

    return response['userId'] as String;
  }

  Future<String> createClientViaFunctions({
    required String email,
    required String password,
    required String name,
    required String organizationId,
    required String divisionId,
    String? phone,
    String? dateOfBirth,
  }) async {
    final response = await _callFunction('create_client', {
      'email': email,
      'password': password,
      'name': name,
      'organizationId': organizationId,
      'divisionId': divisionId,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    });

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to create client');
    }

    return response['userId'] as String;
  }

  Future<void> updateProviderViaFunctions(
    String userId,
    UpdateProviderUserDataModel data,
  ) async {
    final response = await _callFunction('update_provider', {
      'userId': userId,
      if (data.name != null) 'name': data.name,
      if (data.status != null) 'status': data.status!.name,
      if (data.providerRole != null)
        'providerRole': data.providerRole!.map((role) => role.name).toList(),
      if (data.profile != null) 'profile': data.profile,
    });

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to update provider');
    }
  }

  Future<void> updateClientViaFunctions(
    String userId,
    UpdateClientUserDataModel data,
  ) async {
    final response = await _callFunction('update_client', {
      'userId': userId,
      if (data.name != null) 'name': data.name,
      if (data.status != null) 'status': data.status!.name,
      if (data.profile != null) 'profile': data.profile!.toMap(),
    });

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to update client');
    }
  }

  Future<void> deleteUserViaFunctions(String userId, {bool hardDelete = false}) async {
    final response = await _callFunction('delete_user', {
      'userId': userId,
      'hardDelete': hardDelete,
    });

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to delete user');
    }
  }

  Future<void> resetUserPasswordViaFunctions(String userId) async {
    final response = await _callFunction('reset_user_password', {'userId': userId});

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to reset password');
    }
  }

  Future<void> updateUserEmailViaFunctions(String userId, String newEmail) async {
    final response = await _callFunction('update_user_email', {
      'userId': userId,
      'newEmail': newEmail,
    });

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to update email');
    }
  }

  /// Create new provider user with specific document ID, meant for internal use since it must be created with correct auth id.
  Future<ProviderUserModel> _createFirestoreProvider(
    CreateProviderUserDataModel data,
  ) async {
    try {
      final now = DateTime.now();
      final userData = {
        'email': data.email,
        'name': data.name,
        'type': 'provider',
        'providerRole':
            data.providerRole
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

      return ProviderUserModel(
        id: data.id,
        email: data.email,
        name: data.name,
        organizationId: data.organizationId,
        divisionId: data.divisionId,
        providerRole: data.providerRole,
        profile: data.profile ?? {},
        status: UserStatus.active,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      print('Error creating provider user: $e');
      throw Exception('Failed to create provider user');
    }
  }

  /// Create new client user, meant for internal use since it must be created with correct auth id.
  Future<ClientUserModel> _createFirestoreClient(
    CreateClientUserDataModel data,
  ) async {
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

      await _db.collection(_collection).doc(data.id).set(userData);

      return ClientUserModel(
        id: data.id,
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

  /// Hard delete user from Firestore
  Future<bool> hardDeleteFirestore_(String userId) async {
    try {
      final userRef = _db.collection(_collection).doc(userId);
      await userRef.delete();
      return true;
    } catch (e) {
      print('Error hard deleting user: $e');
      return false;
    }
  }

  Future<bool> hardDelete() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return false;
    }
    _authService.deleteAccount();
    return hardDeleteFirestore_(userId);
  }

  /// Create a new provider account with authentication and Firestore user document
  Future<ProviderUserModel> createProvider({
    required String email,
    required String password,
    required String name,
    required String organizationId,
    required String divisionId,
    required List<ProviderRole> providerRole,
    Map<String, dynamic>? profile,
    bool sendEmailVerification = true,
  }) async {
    late ProviderUserModel user;
    
    try {
      // 1. Create Firebase Auth account
      final credential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception("Failed to create authentication account");
      }

      // 2. Send email verification if requested
      if (sendEmailVerification) {
        await _authService.sendEmailVerification();
      }

      // 3. Create user document in Firestore with Firebase Auth UID
      user = await _createFirestoreProvider(
        CreateProviderUserDataModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          organizationId: organizationId,
          divisionId: divisionId,
          providerRole: providerRole,
          profile: profile,
        ),
      );

      return user;
    } catch (e) {
      // Cleanup: delete auth account if Firestore operations fail
      try {
        await hardDelete();
      } catch (deleteError) {
        print('Failed to cleanup auth account: $deleteError');
      }
      rethrow;
    }
  }

  /// Create a new client account with authentication and Firestore user document. If the client is solo, leave organizationId and divisionId empty.
  Future<ClientUserModel> createClient({
    required String email,
    required String password,
    required String name,
    required String organizationId,
    required String divisionId,
    ClientProfileModel? profile,
    bool sendEmailVerification = true,
  }) async {
    late ClientUserModel user;

    try {
      // 1. Create Firebase Auth account
      final credential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception("Failed to create authentication account");
      }

      // 2. Send email verification if requested
      if (sendEmailVerification) {
        await _authService.sendEmailVerification();
      }

      // 3. Create user document in Firestore
      user = await _createFirestoreClient(
        CreateClientUserDataModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          organizationId: organizationId,
          divisionId: divisionId,
          profile: profile,
        ),
      );

      return user;
    } catch (e) {
      // Cleanup: delete auth account if Firestore operations fail
      try {
        await hardDelete();
      } catch (deleteError) {
        print('Failed to cleanup auth account: $deleteError');
      }
      rethrow;
    }
  }

  /// Create account from onboarding quiz
  Future<ClientUserModel> createClientFromOnboarding({
    required String name,
    required String email,
    required String password,
    required Map<String, dynamic> quizAnswers,
    required Map<String, String> quizQuestions,
    bool sendEmailVerification = true,
  }) async {
    late ClientUserModel user;
    try {
      user = await createClient(
        email: email,
        password: password,
        name: name,
        organizationId: '',
        divisionId: '',
      );

      // 3. Save onboarding quiz result under user
      await saveQuizResult_(
        questions: quizQuestions,
        userId: user.id,
        answers: quizAnswers,
        name: 'onboarding',
      );

      return user;
    } catch (e) {
      // Cleanup: delete auth account if quiz save fails
      try {
        await hardDelete();
      } catch (deleteError) {
        print('Failed to cleanup auth account: $deleteError');
      }
      rethrow;
    }
  }

  Future<bool> addClientToDivision({
    required String clientId,
    required String organizationId,
    required String divisionId,
  }) async {
    try {
      final userRef = _db.collection(_collection).doc(clientId);
      await userRef.update({
        'organizationId': organizationId,
        'divisionId': divisionId,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error adding client to organization: $e');
      return false;
    }
  }

  /// Sign in and update last login timestamp
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with Firebase Auth
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return null;
      }

      // 2. Update last login timestamp
      await updateLastLogin();

      // 3. Get and return user data
      return await get();
    } catch (e) {
      rethrow;
    }
  }

  Future<DateTime?> updateLastLogin_(String userId) async {
    try {
      final time = Timestamp.now();
      final userRef = _db.collection(_collection).doc(userId);
      await userRef.update({'lastLogin': time});
      return time.toDate();
    } catch (e) {
      print('Error updating last login: $e');
      throw Exception('Failed to update last login');
    }
  }

  Future<DateTime?> updateLastLogin() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return null;
    }
    return updateLastLogin_(userId);
  }

  /// Check if current user is authenticated
  bool get isAuthenticated {
    return _authService.currentUser != null;
  }

  /// Check if current user's email is verified
  bool get isEmailVerified {
    return _authService.isEmailVerified;
  }
}
