
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/repositories/assignments_repo.dart';
import 'package:stride_core/repositories/division_repo.dart';
import 'package:stride_core/repositories/organization_repo.dart';
import 'package:stride_core/repositories/user_repo.dart';
import 'package:stride_core/services/auth_service.dart';
import 'package:stride_core/services/firebase_config.dart';
import 'package:stride_core/view_models/auth_state_vm.dart';
import 'package:stride_core/view_models/create_account_vm.dart';
import 'package:stride_core/view_models/home_page_vm.dart';
import 'package:stride_core/view_models/onboarding_vm.dart';
import 'package:stride_core/view_models/sign_in_vm.dart';
import 'package:stride_app/views/greeting_v.dart';
import 'package:stride_app/views/home_page_v.dart';
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
        ChangeNotifierProvider(create: (context) => HomePageViewModel()),
        ChangeNotifierProvider(
          create: (context) =>
              OnboardingViewModel(userRepo: context.read<UserRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthStateViewModel(
            authService: context.read<AuthService>(),
            userRepo: context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CreateAccountViewModel(
            organizationRepo: context.read<OrganizationRepository>(),
            divisionRepo: context.read<DivisionRepository>(),
            userRepo: context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SignInViewModel(
            authService: context.read<AuthService>(),
            userRepo: context.read<UserRepository>(),
          ),
          // child: const SignInScreenView(),
        ),
      ],
      child: MyApp(key: Key("HomePage")),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget rebuilds when AuthStateViewModel changes
    final authState = context.watch<AuthStateViewModel>();

    return MaterialApp(
      title: 'Stride',
      theme: AppTheme.lightTheme,
      home: authState.isLoadingUser
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : authState.isSignedIn
          ? HomePageView()
          : GreetingPage(),
      routes: {
        '/onboarding': (context) => OnboardingPage(),
        '/home': (context) => HomePageView(),
      },
    );
  }
}
