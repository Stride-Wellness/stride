import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';

get homeVMP => ChangeNotifierProvider(
  create: (context) => HomeVM(
    authStateController: context.read<AuthStateController>(),
  ),
);

class HomeVM extends ChangeNotifier {
  final AuthStateController authStateController;

  HomeVM({required this.authStateController}) {
    authStateController.addListener(notifyListeners);
  }

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  get authStatus => authStateController.status;

  get isProvider => authStateController.isProvider; 
  

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