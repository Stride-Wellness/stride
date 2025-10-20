import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stride_app/services/auth_service.dart';

class AuthStateViewModel extends ChangeNotifier {
  final AuthService authService;
  User? _user;
  bool _isLoading = true;

  AuthStateViewModel({required this.authService}) {
    // Listen to auth state changes
    authService.authStateChanges.listen((user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
}