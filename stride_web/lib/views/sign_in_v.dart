import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/view_models/sign_in_vm.dart';
import 'package:stride_web/widgets/button.dart';
import 'package:stride_web/widgets/card.dart';
import 'package:stride_web/widgets/divider.dart';
import 'package:stride_web/widgets/input.dart';

class WebSignInView extends StatelessWidget {
  const WebSignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignInViewModel>();
    final authState = context.read<AuthStateController>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: StrideCard(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _AuthHeader(
                    title: 'Stride Dashboard',
                    subtitle: 'Sign in to continue',
                  ),
                  const SizedBox(height: 32),

                  if (viewModel.errorMessage != null)
                    _ErrorBanner(message: viewModel.errorMessage!),

                  FormTextField(
                    controller: emailController,
                    enabled: !viewModel.isLoading,
                    label: 'Email',
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    onChanged: (value) => viewModel.credentials['email'] = value,
                  ),
                  const SizedBox(height: 16),

                  FormTextField(
                    controller: passwordController,
                    enabled: !viewModel.isLoading,
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onChanged: (value) => viewModel.credentials['password'] = value,
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await viewModel.sendPasswordReset();

                              if (viewModel.errorMessage == null && context.mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset email sent!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  PrimaryButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              final success = await viewModel.signIn(dashboardSignIn: true);
                              authState.reloadUser();
                              
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Signed in successfully!'),
                                  ),
                                );
                              }
                            }
                          },
                    isLoading: viewModel.isLoading,
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),

                  const DividerWithText(text: 'or'),
                  const SizedBox(height: 16),

                  Text(
                    'Need access? Contact your administrator',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Reusable Widgets
// ============================================================================

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.health_and_safety,
          size: 64,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}