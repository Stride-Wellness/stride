import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/views/greeting_v.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/repositories/user_repo.dart';
import 'package:stride_core/services/auth_service.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/view_models/home_page_vm.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';
class AccountPageView extends StatelessWidget {
  const AccountPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthStateViewController>();

    if (!authState.isSignedIn) {
      return const Scaffold(body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: const _AccountContent(),
    );
  }
}

class _AccountContent extends StatelessWidget {
  const _AccountContent();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthStateViewController>();

    if (authState.isLoadingUser) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = authState.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KPadding.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: 24),
            _ProfileCard(user: user),
            const SizedBox(height: 24),
            _ActionButtons(),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.person,
            size: 50,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'User',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user?.status.name ?? 'Status Unknown',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserModel? user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthStateViewController>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: authState.user?.email ?? 'N/A',
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.verified_outlined,
              label: 'Email Verified',
              value: authState.isEmailVerified ? 'Yes' : 'No',
              valueColor: authState.isEmailVerified
                  ? Colors.green
                  : Colors.orange,
            ),
            // Provider-specific info
            if (user?.isProvider ?? false) ...[
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.work_outline,
                label: 'Role',
                value:
                    user!.asEmployee?.employeeRole
                        .map((e) => e.name)
                        .join(', ') ??
                    'N/A',
              ),
            ],
            // Client-specific info
            if (user?.isClient ?? false) ...[
              if (user!.asClient?.profile.phone != null) ...[
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: user!.asClient!.profile.phone!,
                ),
              ],
              if (user!.asClient?.profile.dateOfBirth != null) ...[
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: user!.asClient!.profile.dateOfBirth!,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthStateViewController>();
    final authService = context.read<AuthService>();
    final userRepo = context.read<UserRepository>();

    return Column(
      children: [
        if (!authState.isEmailVerified) ...[
          _ActionButton(
            icon: Icons.email,
            label: 'Send Verification Email',
            varient: ButtonVarient.secondary,
            onPressed: () => _sendVerificationEmail(context, authService),
          ),
          const SizedBox(height: 12),
        ],
        _ActionButton(
          icon: Icons.delete_outline,
          label: 'Delete Account',
          varient: ButtonVarient.secondary,
          textColor: Colors.red,
          onPressed: () => _deleteAccount(context, userRepo),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.logout,
          label: 'Sign Out',
          varient: ButtonVarient.primary,
          onPressed: () => _signOut(context, authService),
        ),
      ],
    );
  }

  Future<void> _sendVerificationEmail(
    BuildContext context,
    AuthService authService,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await authService.sendEmailVerification();
      messenger.showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    UserRepository userRepo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await userRepo.hardDelete();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const GreetingPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context, AuthService authService) async {
    final homePageVM = context.read<HomePageViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await authService.signOut();
      homePageVM.currentIndex = 0;
      messenger.showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GreetingPage()),
        (route) => false,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ButtonVarient varient;
  final VoidCallback onPressed;
  final Color? textColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.varient,
    required this.onPressed,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: KSizes.buttonHeight,
      child: Button(
        varient: varient,
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: textColor != null ? TextStyle(color: textColor) : null,
            ),
          ],
        ),
      ),
    );
  }
}
