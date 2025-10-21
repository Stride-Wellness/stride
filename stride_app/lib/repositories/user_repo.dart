import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_app/models/user_m.dart';
import 'package:stride_app/models/onboarding_quiz_result_m.dart';
import 'package:stride_app/services/auth_service.dart';

class UserRepository {
  static const String _collection = 'users';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService;

  UserRepository({required AuthService authService})
    : _authService = authService;

  /// Save onboarding quiz result under user's subcollection
  Future<void> saveQuizResult_({
    required String userId,
    required Map<String, dynamic> answers,
    required String name,
  }) async {
    try {
      final quizResult = OnboardingQuizResult(
        id: '', // Firestore will auto-generate
        name: name,
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
    String name = 'onboarding',
  }) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated to save quiz results');
    }
    return saveQuizResult_(userId: userId, answers: answers, name: name);
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

  /// Create new employee user with specific document ID, meant for internal use since it must be created with correct auth id.
  Future<EmployeeUserModel> _createFirestoreEmployee(
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

  /// Create a new employee account with authentication and Firestore user document
  Future<EmployeeUserModel> createEmployee({
    required String email,
    required String password,
    required String name,
    required String organizationId,
    required String divisionId,
    required List<EmployeeRole> employeeRole,
    Map<String, dynamic>? profile,
    bool sendEmailVerification = true,
  }) async {
    late EmployeeUserModel user;
    
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
      user = await _createFirestoreEmployee(
        CreateEmployeeUserDataModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          organizationId: organizationId,
          divisionId: divisionId,
          employeeRole: employeeRole,
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

  /// Sign out current user
  Future<void> signOut() async {
    await _authService.signOut();
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
