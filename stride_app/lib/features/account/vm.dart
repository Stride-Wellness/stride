import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/home/vm.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';

get accountVMP => ChangeNotifierProvider(
    create: (context) => AccountVM(
      authStateController: context.read<AuthStateController>(),
      homePageVM: context.read<HomeVM>(),
    ),
);


class AccountVM extends ChangeNotifier {
  final AuthStateController authStateController;
  final HomeVM homePageVM;

  AccountVM({required this.authStateController, required this.homePageVM}) {
    // Listen to changes in AuthStateController
    authStateController.addListener(notifyListeners);
  }

  get name => authStateController.user!.name;

  get authState => authStateController.status;

  get userStatus => authStateController.user!.status.name;

  get userEmail => authStateController.user!.email;

  get userEmailVerified => authStateController.isEmailVerified;

  get userEmailVerifiedLabel =>
      authStateController.isEmailVerified ? 'Yes' : 'No';

  get userEmailVerifiedColor =>
      authStateController.isEmailVerified ? Colors.green : Colors.orange;

  get userIsClient => authStateController.isClient;

  get userIsProvider => authStateController.isProvider;

  get userPhone => authStateController.user!.asClient?.profile.phone;

  get providerRole => authStateController.user!.asProvider?.providerRole
      .map((role) => role.name)
      .join(', ');

  get userDateOfBirth =>
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
      homePageVM.setIndex(0);
      return true;
    } catch (e) {
      // Optionally store error for the view to read
      return false;
    }
  }
}
