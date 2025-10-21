import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/constants/layout.dart';
import 'package:stride_app/models/user_m.dart';
import 'package:stride_app/repositories/user_repo.dart';
import 'package:stride_app/services/auth_service.dart';
import 'package:stride_app/view_models/auth_state_vm.dart';
import 'package:stride_app/views/greeting_v.dart';
import 'package:stride_app/widgets/button.dart';

class AccountPageView extends StatelessWidget {
  const AccountPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthStateViewModel>();
    final authService = context.read<AuthService>();
    final userRepo = context.read<UserRepository>();

    if (!authState.isSignedIn) {
      return const Scaffold(body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account'), centerTitle: true),
      body: FutureBuilder<UserModel?>(
        future: userRepo.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading user data: ${snapshot.error}'),
            );
          }

          final user = snapshot.data;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(KPadding.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(context, 'Name', user?.name ?? 'N/A'),
                      const Divider(),
                      _buildInfoRow(
                        context,
                        'Email',
                        authState.user?.email ?? 'N/A',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        context,
                        'Email Verified',
                        authState.isEmailVerified ? 'Yes' : 'No',
                        valueColor: authState.isEmailVerified
                            ? Colors.green
                            : Colors.orange,
                      ),
                      // Check if user is employee using the isEmployee getter
                      if (user?.isEmployee ?? false) ...[
                        const Divider(),
                        _buildInfoRow(
                          context,
                          'Role',
                          // Use asEmployee getter to safely access employee properties
                          user!.asEmployee?.employeeRole
                                  .map((e) => e.name)
                                  .join(', ') ??
                              'N/A',
                        ),
                      ],
                      const Divider(),
                      _buildInfoRow(
                        context,
                        'Status',
                        user?.status.name ?? 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Send Verification Email (if not verified)
                  if (!authState.isEmailVerified)
                    SizedBox(
                      width: double.infinity,
                      height: KSizes.buttonHeight,
                      child: Button(
                        varient: ButtonVarient.secondary,
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await authService.sendEmailVerification();
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
                        child: const Text('Send Verification Email'),
                      ),
                    ),
                  if (!authState.isEmailVerified) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: KSizes.buttonHeight,
                    child: Button(
                      varient: ButtonVarient.secondary,
                      onPressed: () async {
                        userRepo.hardDelete();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GreetingPage(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Delete Account'),
                    ),
                  ), 

                  // Spacer
                  const Expanded(child: SizedBox()),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    height: KSizes.buttonHeight,
                    child: Button(
                      varient: ButtonVarient.primary,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await authService.signOut();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Signed out successfully'),
                            ),
                          );
                          // No need to navigate - AuthStateViewModel will handle it
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error signing out: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
