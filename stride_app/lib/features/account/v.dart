import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/account/vm.dart';
import 'package:stride_app/views/greeting_v.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';

class AccountV extends StatelessWidget {
  const AccountV({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountVM>();

    switch (vm.authState) {
      case AuthStatus.signedOut:
        return const Scaffold(body: Center(child: Text('Not signed in')));
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedIn:
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Header
              _ProfileHeader(vm: vm),
              const SizedBox(height: 24),
              // Profile Card
              _ProfileCard(vm: vm),
              const SizedBox(height: 24),
              // Action Buttons
              Column(
                children: [
                  if (!vm.userEmailVerified) ...[
                    _VerifyEmailButton(vm: vm),
                    const SizedBox(height: 12),
                  ],
                  _DeleteAccountButton(vm: vm),
                  const SizedBox(height: 12),
                  _SignOutButton(vm: vm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Organizational Widgets

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.vm,
  });

  final AccountVM vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withAlpha(20),
          child: Icon(
            Icons.person,
            size: 50,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          vm.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          vm.userStatus,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.vm,
  });

  final AccountVM vm;

  @override
  Widget build(BuildContext context) {
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
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: vm.userEmail,
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.verified_outlined,
              label: 'Email Verified',
              value: vm.userEmailVerifiedLabel,
              valueColor: vm.userEmailVerifiedColor,
            ),
            // Provider-specific info
            if (vm.userIsProvider ?? false) ...[
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.work_outline,
                label: 'Role',
                value: vm.providerRole,
              ),
            ],
            // Client-specific info
            if (vm.userIsClient ?? false) ...[
              if (vm.userPhone != null) ...[
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: vm.userPhone,
                ),
              ],
              if (vm.userDateOfBirth != null) ...[
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: vm.userDateOfBirth,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _VerifyEmailButton extends StatelessWidget {
  const _VerifyEmailButton({
    required this.vm,
  });

  final AccountVM vm;

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.email,
      label: 'Send Verification Email',
      varient: ButtonVarient.secondary,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await vm.sendEmailVerification();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Verification email sent!'),
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({
    required this.vm,
  });

  final AccountVM vm;

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.delete_outline,
      label: 'Delete Account',
      varient: ButtonVarient.secondary,
      textColor: Colors.red,
      onPressed: () async {
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await vm.deleteAccount();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const GreetingPage(),
              ),
              (route) => false,
            );
          }
        }
      },
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({
    required this.vm,
  });

  final AccountVM vm;

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.logout,
      label: 'Sign Out',
      varient: ButtonVarient.primary,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final success = await vm.signOutAndResetHomeIndex();
        if (success) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Signed out successfully'),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const GreetingPage(),
            ),
            (route) => false,
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error signing out'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}


// Reusable Widgets

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
