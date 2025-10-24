// stride_web/lib/main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/services/auth_service.dart';
import 'package:stride_core/repositories/user_repo.dart';
import 'package:stride_core/repositories/organization_repo.dart';
import 'package:stride_core/repositories/division_repo.dart';
import 'package:stride_core/repositories/assignments_repo.dart';
import 'package:stride_core/services/firebase_config.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/view_models/divisions_vm.dart';
import 'package:stride_core/view_models/sign_in_vm.dart';
import 'package:stride_core/view_models/user_vm.dart';
import 'package:stride_ui/theme/app_theme.dart';
import 'package:stride_web/views/sign_in_v.dart';
import 'package:url_strategy/url_strategy.dart';

import 'views/dashboard_v.dart';
// import 'views/admin_panel_v.dart';
// import 'views/web_login_v.dart';
// import 'views/clients_list_v.dart';
// import 'views/analytics_v.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy(); // Remove # from URLs

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
        ChangeNotifierProvider(create: (context) => DivisionsViewModel(
          divisionRepo: context.read<DivisionRepository>(),
        )),
        ChangeNotifierProvider(
          create: (context) => UsersViewModel(
            userRepo: context.read<UserRepository>(),
            assignmentsRepo: context.read<AssignmentsRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthStateViewController(
            authService: context.read<AuthService>(),
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
      child: const StrideWebApp(),
    ),
  );
}

class StrideWebApp extends StatelessWidget {
  const StrideWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthStateViewController>();

    // Define routes
    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isSignedIn = authState.isSignedIn;
        final isLoading = authState.isLoadingUser;

        final isLoginRoute = state.matchedLocation == '/login';

        // Don't redirect while loading
        if (isLoading) return null;

        // Redirect to login if not signed in
        if (!isSignedIn && !isLoginRoute && !isLoading) {
          return '/login'; // Change to '/login' when login view is implemented
        }
        // Redirect to dashboard if signed in and on login page
        if (isSignedIn &&
            isLoginRoute &&
            !isLoading &&
            authState.user?.asProvider != null &&
            authState.user!.asProvider!.providerRole.contains(
              ProviderRole.admin,
            )) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const WebSignInView(),
        ),
        GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardView(),
        ),
        // GoRoute(
        //   path: '/clients',
        //   builder: (context, state) => const ClientsListView(),
        // ),
        // GoRoute(
        //   path: '/analytics',
        //   builder: (context, state) => const AnalyticsView(),
        // ),
        // GoRoute(
        //   path: '/admin',
        //   builder: (context, state) => const AdminPanelView(),
        // ),
      ],
    );

    return MaterialApp.router(
      title: 'Stride Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
