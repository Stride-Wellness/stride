import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/views/provider_clients_list_v.dart';
import 'package:stride_app/views/account_screen_v.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/view_models/home_page_vm.dart';

List<Widget> pages({required bool isProvider}) {
    if (!isProvider) {
      return [
        const FeedPage(),
        const ActivityPage(),
        const NewSurveyPage(),
        const SurveysPage(),
        const AccountPageView(),
      ];
    }
    
    return [
      const FeedPage(),
      const ProviderClientsListView(),
      const AccountPageView(),
    ];
  }
  
class HomePageView extends StatelessWidget {
  const HomePageView({super.key});



  @override
  Widget build(BuildContext context) {
    final homePageVM = context.watch<HomePageViewModel>();
    final authStateVM = context.watch<AuthStateViewController>();
    
    // Show loading while user data is being fetched
    if (authStateVM.isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isProvider = authStateVM.isProvider;


    return Scaffold(
      body: pages(isProvider: isProvider)[homePageVM.currentIndex],
      bottomNavigationBar: homePageVM.bottomNavigationBar(isProvider: isProvider),
    );
  }
}


// Feed Page - Instagram-style scrollable feed
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stride'),
        centerTitle: false,
      ),
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(8),
            height: 400,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Post ${index + 1}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Activity Page
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
      ),
      body: const Center(
        child: Placeholder(),
      ),
    );
  }
}

// New Survey Page (middle button)
class NewSurveyPage extends StatelessWidget {
  const NewSurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Survey'),
      ),
      body: const Center(
        child: Placeholder(),
      ),
    );
  }
}

// Surveys Page
class SurveysPage extends StatelessWidget {
  const SurveysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveys'),
      ),
      body: const Center(
        child: Placeholder(),
      ),
    );
  }
}

// Profile Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Placeholder(),
      ),
    );
  }
}