import 'package:stride_app/models/user_m.dart';
import 'package:stride_app/services/storage_service.dart';

class UserRepository {
  final StorageService _storage = StorageService();
  var userCache = <String, UserDataModel>{}; // Keep cache for performance

  UserRepository();

  // === AUTH METHODS ===
  
  /// Login user and save their ID
  Future<bool> loginUser(String userId) async {
    return await _storage.saveLoginState(userId: userId, isLoggedIn: true);
  }
  
  /// Logout current user
  Future<bool> logoutUser() async {
    userCache.clear(); // Clear cache
    return await _storage.clearLoginState();
  }
  
  /// Get current logged-in user ID
  String? getCurrentUserId() {
    return _storage.getCurrentUserId();
  }
  
  /// Check if user is logged in
  bool isLoggedIn() {
    return _storage.isLoggedIn();
  }
  
  /// Get current logged-in user data
  Future<UserDataModel?> getCurrentUser() async {
    String? userId = getCurrentUserId();
    if (userId == null) return null;
    return await getUser(userId);
  }

  // === USER DATA METHODS ===

  Future<UserDataModel?> getUser(String userId) async {
    // Check cache first
    if (userCache.containsKey(userId)) {
      return userCache[userId];
    }
    
    // Load from storage
    Map<String, dynamic>? userData = _storage.getUserData(userId);
    if (userData != null) {
      UserDataModel user = UserDataModel.fromMap(userData);
      userCache[userId] = user; // Cache it
      return user;
    }
    
    return null;
  }

  Future<bool> saveUser(UserDataModel user) async {
    // Save to cache
    userCache[user.id] = user;
    
    // Save to persistent storage
    Map<String, dynamic> userData = user.toMap();
    return await _storage.saveUserData(user.id, userData);
  }

  Future<String> createUser({required String name, required Map<String, List<String>> quizAnswers, required String email}) async {
    String userId = DateTime.now().millisecondsSinceEpoch.toString();
    UserDataModel newUser = UserDataModel(id: userId, name: name, email: email, quizAnswers: quizAnswers);

    bool saved = await saveUser(newUser);
    if (saved) {
      // Auto-login the new user
      await loginUser(userId);
    }

    return userId;
  }

  Future<bool> deleteUser(String userId) async {
    userCache.remove(userId);
    return await _storage.deleteUserData(userId);
  }

  Future<List<UserDataModel>> getAllUsers() async {
    // This is expensive - only use if needed
    // In a real app, you'd probably have a separate method for this
    return userCache.values.toList();
  }

}
