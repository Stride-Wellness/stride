import 'package:flutter/material.dart';
import 'package:stride_app/controllers/page_controller.dart';
import 'package:stride_app/controllers/auth_state_controller.dart';

class HomePageVM extends ChangeNotifier {
  final AuthStateController authStateController;
  final HomePageController pageController;

  HomePageVM({
    required this.pageController,
    required this.authStateController,
  }) {
    authStateController.addListener(notifyListeners);
  }

  int get currentIndex => pageController.currentIndex;

  AuthStatus get authStatus => authStateController.status;

  bool get isProvider => authStateController.isProvider;

  void setIndex(int index) {
    pageController.setIndex(index);
    notifyListeners();
  }

  @override
  void dispose() {
    authStateController.removeListener(notifyListeners);
    super.dispose();
  }
}
