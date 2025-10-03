import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class StorageService {
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userDataBoxName = 'user_data';
  
  // SharedPreferences instance
  SharedPreferences? _prefs;
  
  // Hive box for complex data
  Box? _userDataBox;
  
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  /// Initialize storage service - call this once in main()
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await Hive.initFlutter();
    _userDataBox = await Hive.openBox(_userDataBoxName);
  }
  
  // === AUTH STATE MANAGEMENT ===
  
  /// Save user login state and ID
  Future<bool> saveLoginState({required String userId, required bool isLoggedIn}) async {
    try {
      await _prefs?.setString(_userIdKey, userId);
      await _prefs?.setBool(_isLoggedInKey, isLoggedIn);
      return true;
    } catch (e) {
      print('Error saving login state: $e');
      return false;
    }
  }
  
  /// Get current user ID
  String? getCurrentUserId() {
    return _prefs?.getString(_userIdKey);
  }
  
  /// Check if user is logged in
  bool isLoggedIn() {
    return _prefs?.getBool(_isLoggedInKey) ?? false;
  }
  
  /// Clear login state (logout)
  Future<bool> clearLoginState() async {
    try {
      await _prefs?.remove(_userIdKey);
      await _prefs?.remove(_isLoggedInKey);
      return true;
    } catch (e) {
      print('Error clearing login state: $e');
      return false;
    }
  }
  
  // === USER DATA MANAGEMENT ===
  
  /// Save user data object
  Future<bool> saveUserData(String userId, Map<String, dynamic> userData) async {
    try {
      await _userDataBox?.put(userId, userData);
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }
  
  /// Get user data
  Map<String, dynamic>? getUserData(String userId) {
    try {
      return _userDataBox?.get(userId)?.cast<String, dynamic>();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
  
  /// Delete user data
  Future<bool> deleteUserData(String userId) async {
    try {
      await _userDataBox?.delete(userId);
      return true;
    } catch (e) {
      print('Error deleting user data: $e');
      return false;
    }
  }
  
  // === SETTINGS & PREFERENCES ===
  
  /// Save app settings
  Future<bool> saveSetting(String key, dynamic value) async {
    try {
      if (value is String) {
        await _prefs?.setString(key, value);
      } else if (value is bool) {
        await _prefs?.setBool(key, value);
      } else if (value is int) {
        await _prefs?.setInt(key, value);
      } else if (value is double) {
        await _prefs?.setDouble(key, value);
      } else {
        // For complex objects, store as JSON string
        await _prefs?.setString(key, json.encode(value));
      }
      return true;
    } catch (e) {
      print('Error saving setting: $e');
      return false;
    }
  }
  
  /// Get app setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      if (T == String) {
        return _prefs?.getString(key) as T? ?? defaultValue;
      } else if (T == bool) {
        return _prefs?.getBool(key) as T? ?? defaultValue;
      } else if (T == int) {
        return _prefs?.getInt(key) as T? ?? defaultValue;
      } else if (T == double) {
        return _prefs?.getDouble(key) as T? ?? defaultValue;
      } else {
        // For complex objects, decode from JSON
        String? jsonString = _prefs?.getString(key);
        if (jsonString != null) {
          return json.decode(jsonString) as T;
        }
        return defaultValue;
      }
    } catch (e) {
      print('Error getting setting: $e');
      return defaultValue;
    }
  }
  
  /// Clear all storage (nuclear option)
  Future<bool> clearAll() async {
    try {
      await _prefs?.clear();
      await _userDataBox?.clear();
      return true;
    } catch (e) {
      print('Error clearing all storage: $e');
      return false;
    }
  }
}