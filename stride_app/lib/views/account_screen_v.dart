import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/constants/layout.dart';
import 'package:stride_app/models/user_m.dart';
import 'package:stride_app/repositories/user_repo.dart';
import 'package:stride_app/widgets/button.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserDataModel? currentUser;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userRepo = context.read<UserRepository>();
      
      if (!userRepo.isLoggedIn()) {
        setState(() {
          errorMessage = 'No user logged in';
          isLoading = false;
        });
        return;
      }

      UserDataModel? user = await userRepo.getCurrentUser();
      
      setState(() {
        currentUser = user;
        isLoading = false;
        if (user == null) {
          errorMessage = 'Failed to load user data';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading user data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final userRepo = context.read<UserRepository>();
      bool success = await userRepo.logoutUser();
      
      if (success) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      } else {
        _showSnackBar('Failed to logout');
      }
    } catch (e) {
      _showSnackBar('Error during logout: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (currentUser == null) {
      return _buildNoUserState();
    }

    return _buildUserProfile();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KPadding.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Button(
              varient: ButtonVarient.primary,
              onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUserState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KPadding.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No user logged in',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Please log in to view your account information',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Button(
              varient: ButtonVarient.primary,
              onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(KPadding.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          const SizedBox(height: 32),
          _buildUserInfo(),
          const SizedBox(height: 32),
          if (currentUser!.quizAnswers.isNotEmpty) ...[
            _buildQuizAnswers(),
            const SizedBox(height: 32),
          ],
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              currentUser!.name.isNotEmpty 
                  ? currentUser!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentUser!.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            currentUser!.email,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoTile('User ID', currentUser!.id),
        _buildInfoTile('Name', currentUser!.name),
        _buildInfoTile('Email', currentUser!.email),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizAnswers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Onboarding Answers',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: currentUser!.quizAnswers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatQuestionKey(entry.key),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value.join(', '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatQuestionKey(String key) {
    // Convert snake_case to Title Case
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Button(
          varient: ButtonVarient.secondary,
          onPressed: () {
            // Navigate to edit profile (if implemented)
            _showSnackBar('Edit profile feature coming soon!');
          },
          child: const Text('Edit Profile'),
        ),
        const SizedBox(height: 12),
        Button(
          varient: ButtonVarient.secondary,
          onPressed: () {
            // Navigate to settings (if implemented)
            _showSnackBar('Settings feature coming soon!');
          },
          child: const Text('Settings'),
        ),
        const SizedBox(height: 24),
        Button(
          varient: ButtonVarient.primary,
          onPressed: _logout,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ],
    );
  }
}
