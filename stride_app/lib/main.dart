import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/repositories/division_repo.dart';
import 'package:stride_app/repositories/organization_repo.dart';
import 'package:stride_app/repositories/user_repo.dart';
import 'package:stride_app/services/auth_service.dart';
import 'package:stride_app/services/firebase_config.dart';
import 'package:stride_app/view_models/auth_state_vm.dart';
import 'package:stride_app/view_models/create_account_vm.dart';
import 'package:stride_app/view_models/onboarding_vm.dart';
import 'package:stride_app/views/account_screen_v.dart';
import 'package:stride_app/views/greeting_v.dart';
import 'package:stride_app/views/onboarding_v.dart';

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

        ChangeNotifierProvider(
          create: (context) =>
              OnboardingViewModel(userRepo: context.read<UserRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthStateViewModel(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CreateAccountViewModel(
            organizationRepo: context.read<OrganizationRepository>(),
            divisionRepo: context.read<DivisionRepository>(),
            userRepo: context.read<UserRepository>(),
          ),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: 1.2,
        ),
      ),
      home: authState.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : authState.isSignedIn
          ? AccountPageView()
          : GreetingPage(),
      routes: {
        '/onboarding': (context) => OnboardingPage(),
        '/account': (context) => AccountPageView(),
      },
    );
  }
}
