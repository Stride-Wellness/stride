import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/repositories/user_repo.dart';
import 'package:stride_app/services/storage_service.dart';
import 'package:stride_app/view_models/onboarding_vm.dart';
import 'package:stride_app/views/account_screen_v.dart';
import 'package:stride_app/views/favourites_v.dart';
import 'package:stride_app/views/generator_v.dart';
import 'package:stride_app/views/greeting_v.dart';
import 'package:stride_app/views/onboarding_v.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyAppState()),
        ChangeNotifierProvider(create: (context) => OnboardingViewModel()),
        Provider(create: (context) => UserRepository()),
      ],
      child: MyApp(key: Key("HomePage")),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stride',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: 1.2, // 20% bigger for better readability
        ),
      ),
      // SignInPage decides whether to start onboarding (wizard) or login.
      home: GreetingPage(),
      routes: {
        '/home': (context) => MyHomePage(),
        '/onboarding': (context) => OnboardingPage(),
        '/account': (context) => AccountScreen(),
      },
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favourites = <WordPair>[];

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  // returns true if the word was added to favourites, otherwise false
  bool toggleFavourite(WordPair word) {
    if (favourites.contains(word)) {
      favourites.remove(word);
    } else {
      favourites.add(word);
    }
    notifyListeners();
    return favourites.contains(word);
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavouritesPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          bottomNavigationBar: constraints.maxWidth >= 600
              ? null
              : NavigationBar(
                  // extended: false,
                  height: 100,
                  destinations: [
                    NavigationDestination(
                      icon: Icon(Icons.home),
                      label: "Home",
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite),
                      label: "Favorites",
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.exit_to_app),
                      label: "Sign Out",
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      if (value == 2) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                        return;
                      }
                      selectedIndex = value;
                    });
                  },
                ),
          body: Row(
            children: [
              if (constraints.maxWidth >= 600)
                NavigationRail(
                  extended: constraints.maxWidth >= 800,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text("Home"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text("Favorites"),
                    ),
                  ],
                  selectedIndex: 0,
                  onDestinationSelected: (value) {
                    print('selected: $value');
                  },
                ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
