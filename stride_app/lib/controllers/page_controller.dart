import 'package:flutter/material.dart';
import 'package:stride_app/controllers/auth_state_controller.dart';


class HomePageController extends ChangeNotifier {
  final AuthStateController authStateController;

  HomePageController({required this.authStateController}) {
    authStateController.addListener(notifyListeners);
  }

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;


  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // Widget bottomNavigationBar({required bool isProvider}) {
  //   return isProvider
  //       ? ProviderBottomBar(
  //           index: _currentIndex,
  //           onTap: setIndex,
  //         )
  //       : ClientBottomBar(
  //           index: _currentIndex,
  //           onTap: setIndex,
  //         );
  // }

  
}