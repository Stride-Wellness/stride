import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:stride_core/models/user_m.dart';
import '../repositories/user_repo.dart';
import '../services/auth_service.dart';

class AuthStateViewController extends ChangeNotifier {
  final UserRepository _userRepo;
  final AuthService _authService;
  
  UserModel? _user;
  bool _isLoadingUser = false;

  AuthStateViewController({
    required UserRepository userRepo,
    required AuthService authService,
  }) : _userRepo = userRepo,
       _authService = authService {
    // Listen to auth state changes from AuthService
    _authService.authStateChanges.listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUser();
        notifyListeners();
      } else {
        _user = null;
        _isLoadingUser = false;
        notifyListeners();
      }
    });
  }

  // Expose data
  UserModel? get user => _user;
  bool get isSignedIn => _authService.currentUser != null;
  bool get isEmailVerified => _authService.currentUser?.emailVerified ?? false;
  bool get isLoadingUser => _isLoadingUser;
  bool get isProvider => _user?.isProvider ?? false;
  bool get isClient => _user?.isClient ?? false;

  // Load user from repository
  Future<void> _loadUser() async {
    _isLoadingUser = true;
    notifyListeners();

    _user = await _userRepo.get();

    _isLoadingUser = false;
    notifyListeners();
  }

  // Delegate actions to repository
  Future<void> reloadUser() async {
    await _loadUser();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _userRepo.signOut();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await _userRepo.hardDelete();
    notifyListeners();
  }
}