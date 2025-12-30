import 'package:flutter/material.dart';
import 'package:stride_app/controllers/page_controller.dart';
import 'package:stride_app/controllers/auth_state_controller.dart';

class AccountVM extends ChangeNotifier {
  final AuthStateController authStateController;
  final HomePageController homePageController;

  AccountVM({
    required this.authStateController,
    required this.homePageController,
  }) {
    // Listen to changes in AuthStateController
    authStateController.addListener(notifyListeners);
  }

  String get name => authStateController.user!.name;

  AuthStatus get authState => authStateController.status;

  String get userStatus => authStateController.user!.status.name;

  String get userEmail => authStateController.user!.email;

  bool get userEmailVerified => authStateController.isEmailVerified;

  String get userEmailVerifiedLabel =>
      authStateController.isEmailVerified ? 'Yes' : 'No';

  Color get userEmailVerifiedColor =>
      authStateController.isEmailVerified ? Colors.green : Colors.orange;

  bool? get userIsClient => authStateController.isClient;

  bool? get userIsProvider => authStateController.isProvider;

  String? get userPhone => authStateController.user!.asClient?.profile.phone;

  String get providerRole => authStateController.user!.asProvider!.providerRole
      .map((role) => role.name)
      .join(', ');

  String? get userDateOfBirth =>
      authStateController.user!.asClient?.profile.dateOfBirth;

  Future<void> sendEmailVerification() async {
    await authStateController.sendEmailVerification();
  }

  Future<void> signOut() async {
    await authStateController.signOut();
  }

  Future<void> deleteAccount() async {
    await authStateController.deleteAccount();
  }

  Future<bool> signOutAndResetHomeIndex() async {
    try {
      await signOut();
      homePageController.setIndex(0);
      return true;
    } catch (e) {
      // Optionally store error for the view to read
      return false;
    }
  }

  @override
  void dispose() {
    authStateController.removeListener(notifyListeners);
    super.dispose();
  }
}
