import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/controllers/auth_state_controller.dart';
import 'package:stride_app/controllers/page_controller.dart';
import 'package:stride_app/features/home/vm.dart';
import 'package:stride_app/features/home/widgets/client_bottom_bar.dart';
import 'package:stride_app/features/home/widgets/provider_bottom_bar.dart';
import 'package:stride_app/features/quizzes/v.dart';
import 'package:stride_app/features/provider_clients/v.dart';
import 'package:stride_app/features/account/v.dart';
import 'package:stride_app/features/exercise/v.dart'; 


const providerPages = [
  ExerciseV(),
  ProviderClientsListV(),
  AccountV(),
];

const clientPages = [
  ExerciseV(),
  _ActivityPage(),
  ClientQuizzesV(),
  AccountV(),
];

class HomePageView extends StatelessWidget {
  const HomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomePageVM(
        pageController: context.read<HomePageController>(),
        authStateController: context.read<AuthStateController>(),
      ),
      child: const _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomePageVM>();

    switch (vm.authStatus) {
      case AuthStatus.signedOut:
        return const Scaffold(
          body: Center(child: Text('Please sign in to continue.')),
        );
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.signedIn:
        break; // Proceed to build the main UI
    }

    return Scaffold(
      body: vm.isProvider ? providerPages[vm.currentIndex] : clientPages[vm.currentIndex],
      bottomNavigationBar: vm.isProvider
          ? ProviderBottomBar(
              index: vm.currentIndex,
              onTap: vm.setIndex,
            )
          : ClientBottomBar(
              index: vm.currentIndex,
              onTap: vm.setIndex,
            ),
    );
  }
}


// Activity Page
class _ActivityPage extends StatelessWidget {
  const _ActivityPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: const Center(child: Placeholder()),
    );
  }
}
