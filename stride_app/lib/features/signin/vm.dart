import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/repositories/user_repo.dart';
import 'package:stride_core/services/auth_service.dart';

get signInVMP => ChangeNotifierProvider(
    create: (context) => SignInVM(
      authService: context.read<AuthService>(),
      userRepo: context.read<UserRepository>(),
    ),
  );

class SignInVM extends ChangeNotifier {
  final AuthService authService;
  final UserRepository userRepo;

  SignInVM({required this.authService, required this.userRepo});

  Map<String, String> credentials = {
    "email": "",
    "password": "",
  };

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isValid {
    return credentials["email"]!.isNotEmpty &&
           credentials["password"]!.isNotEmpty &&
           credentials["email"]!.contains('@');
  }

  void updateCredentials(List<String> selected) {
    for (String entry in selected) {
      if (entry.contains(':')) {
        List<String> parts = entry.split(':');
        if (parts.length == 2) {
          String fieldKey = parts[0];
          String value = parts[1];
          credentials[fieldKey] = value;
        }
      }
    }
    notifyListeners();
  }

  Future<bool> signIn({bool dashboardSignIn = false}) async {
    if (!isValid) {
      _errorMessage = "Please enter a valid email and password";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.signInWithEmailAndPassword(
        email: credentials["email"]!,
        password: credentials["password"]!,
      );
      
      if (dashboardSignIn) {
        final user = await userRepo.get();
        // print(user!.asProvider?.providerRole.contains('admin'));
        if (user == null ||
            null == user.asProvider?.providerRole.contains('admin')) {
          await authService.signOut();
          _errorMessage = "Access denied. Admins only.";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> sendPasswordReset() async {
    if (credentials["email"]!.isEmpty || !credentials["email"]!.contains('@')) {
      _errorMessage = "Please enter a valid email address";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.sendPasswordResetEmail(credentials["email"]!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}