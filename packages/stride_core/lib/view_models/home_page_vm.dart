import 'package:flutter/material.dart';
import 'package:stride_ui/widgets/client_bottom_bar.dart';
import 'package:stride_ui/widgets/provider_bottom_bar.dart';

class HomePageViewModel extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;
  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Widget bottomNavigationBar({required bool isProvider}) {
    return isProvider
        ? ProviderBottomBar(
            index: _currentIndex,
            onTap: setIndex,
          )
        : ClientBottomBar(
            index: _currentIndex,
            onTap: setIndex,
          );
  }

  
}