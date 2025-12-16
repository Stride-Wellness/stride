import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/models/user_m.dart';
import '../repositories/user_repo.dart';
import '../services/auth_service.dart';

get authStateControllerProvider => ChangeNotifierProvider(
      create: (context) => AuthStateController(
        authService: context.read<AuthService>(),
        userRepo: context.read<UserRepository>(),
      ),
    );

enum AuthStatus {
  signedOut,
  loading,
  signedIn,
}

class AuthStateController extends ChangeNotifier {
  final UserRepository _userRepo;
  final AuthService _authService;
  
  UserModel? _user;
  bool _isLoadingUser = false;

  AuthStateController({
    required UserRepository userRepo,
    required AuthService authService,
  }) : _userRepo = userRepo,
       _authService = authService {
    // Listen to auth state changes from AuthService
    _authService.authStateChanges.listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUser();
      } else {
        _user = null;
        _isLoadingUser = false;
        notifyListeners();
      }
    });
  }

  // Expose data
  UserModel? get user => _user;
  bool get isEmailVerified => _authService.currentUser?.emailVerified ?? false;
  bool get isProvider => _user?.isProvider ?? false;
  bool get isClient => _user?.isClient ?? false;

  AuthStatus get status {
    if (_isLoadingUser) return AuthStatus.loading;
    return _user != null ? AuthStatus.signedIn : AuthStatus.signedOut;
  }

  // Load user from repository
  Future<void> _loadUser() async {
    _isLoadingUser = true;
    notifyListeners();

    try {
    _user = await _userRepo.get();
    } catch (e) {
      // TODO: handle/log error (or expose an error variable)
      _user = null;
    }

    _isLoadingUser = false;
    notifyListeners();
  }

  // Delegate actions to repository
  Future<void> reloadUser() async {
    await _loadUser();
    notifyListeners();
  }
  
  Future<void> signOut() async {
    _user = null;
    _isLoadingUser = false;
    notifyListeners();
    await _authService.signOut();
  }

  Future<void> deleteAccount() async {
    await _userRepo.hardDelete();
    notifyListeners();
  }


  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }
}