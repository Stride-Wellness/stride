import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/account/vm.dart';
import 'package:stride_app/features/exercise/vm.dart';
import 'package:stride_app/features/home/vm.dart';
import 'package:stride_app/features/provider_clients/vm.dart';
import 'package:stride_app/features/quizzes/vm.dart';
import 'package:stride_app/features/signin/vm.dart';
import 'package:stride_app/features/signup/vm.dart';
import 'package:stride_core/repositories/assignments_repo.dart';
import 'package:stride_core/repositories/division_repo.dart';
import 'package:stride_core/repositories/exercise_repo.dart';
import 'package:stride_core/repositories/organization_repo.dart';
import 'package:stride_core/repositories/user_repo.dart';
import 'package:stride_core/services/auth_service.dart';
import 'package:stride_core/services/firebase_config.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/view_models/onboarding_vm.dart';
import 'package:stride_app/views/greeting_v.dart';
import 'package:stride_app/features/home/v.dart';
import 'package:stride_app/views/onboarding_v.dart';
import 'package:stride_ui/theme/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with our configuration helper
  await FirebaseConfig.initialize();

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider(create: (context) => AuthService()),

        // Repositories
        Provider(
          create: (context) =>
              UserRepository(authService: context.read<AuthService>()),
        ),
        Provider(create: (context) => OrganizationRepository()),
        Provider(create: (context) => DivisionRepository()),
        Provider(
          create: (context) =>
              AssignmentsRepository(authService: context.read<AuthService>()),
        ),
        Provider(create: (context) => ExerciseRepository()),

        // Controllers
        authStateControllerProvider,

        // Viewm Models
        homeVMP,
        ChangeNotifierProvider(
          create: (context) =>
              OnboardingViewModel(userRepo: context.read<UserRepository>()),
        ),

        ChangeNotifierProvider(
          create: (context) => CreateAccountVM(
            organizationRepo: context.read<OrganizationRepository>(),
            divisionRepo: context.read<DivisionRepository>(),
            userRepo: context.read<UserRepository>(),
          ),
        ),
        clientQuizzesVMP,
        exerciseVMP,
        providerClientsVMProvider,
        signInVMP,
        accountVMP,
      ],
      child: App(key: Key("HomePage")),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget rebuilds when AuthStateViewModel changes
    final authState = context.watch<AuthStateController>();

    return MaterialApp(
      title: 'Stride',
      theme: AppTheme.lightTheme,
      home: authState.status == AuthStatus.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : authState.status == AuthStatus.signedIn
          ? HomePageView()
          : GreetingPage(),
      routes: {
        '/onboarding': (context) => OnboardingPage(),
        '/home': (context) => HomePageView(),
      },
    );
  }
}
