import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/controllers/auth_state_controller.dart';
import 'package:stride_app/features/client_onboarding_quiz/v.dart';
import 'package:stride_app/features/client_onboarding_quiz/vm.dart';
import 'package:stride_app/features/inviation_onboarding_quiz/v.dart';
import 'package:stride_app/features/provider_onboarding_quiz/v.dart';
import 'package:stride_app/features/signup/vm.dart';
import 'package:stride_core/repositories/division_repo.dart';
import 'package:stride_core/repositories/invitations_repo.dart';
import 'package:stride_core/repositories/organization_repo.dart';
import 'package:stride_core/repositories/user_repo.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';

/// Entry point for signup flow - shows the initial selection screen
class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SignupOptionsScreen();
  }
}

/// Initial screen where users choose their signup path
class _SignupOptionsScreen extends StatelessWidget {
  const _SignupOptionsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            children: [
              const Text(
                "To get started, please tell us help us understand what you need from Stride!",
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _SignupOptionButton(
                text: "I am using Stride for myself.",
                variant: ButtonVariant.primary,
                onPressed: () => _handleClientSignup(context),
              ),
              _SignupOptionButton(
                text: "I am helping other people.",
                variant: ButtonVariant.secondary,
                onPressed: () => _handleProviderSignup(context),
              ),
              _SignupOptionButton(
                text: "I have a code.",
                variant: ButtonVariant.secondary,
                onPressed: () => _handleCodeSignup(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleClientSignup(BuildContext context) async {
    final quizData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientOnboardingQuizView(
          mode: ClientOnboardingMode.clientSelfRegistration,
        ),
      ),
    );

    if (quizData != null && context.mounted) {
      _navigateToSignupForm(
        context,
        signupType: SignupType.client,
        quizData: quizData,
      );
    }
  }

  Future<void> _handleProviderSignup(BuildContext context) async {
    final quizData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ProviderOnboardingQuizView()),
    );

    if (quizData != null && context.mounted) {
      _navigateToSignupForm(
        context,
        signupType: SignupType.provider,
        quizData: quizData,
      );
    }
  }

  Future<void> _handleCodeSignup(BuildContext context) async {
    final quizData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const InvitationCodeInputScreen()),
    );

    if (quizData != null && context.mounted) {
      _navigateToSignupForm(
        context,
        signupType: SignupType.client,
        quizData: quizData,
      );
    }
  }

  void _navigateToSignupForm(
    BuildContext context, {
    required SignupType signupType,
    required Map<String, dynamic> quizData,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _SignupFormScreen(signupType: signupType, quizData: quizData),
      ),
    );
  }
}

/// Button widget for signup options
class _SignupOptionButton extends StatelessWidget {
  const _SignupOptionButton({
    required this.text,
    required this.variant,
    required this.onPressed,
  });

  final String text;
  final ButtonVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KPadding.small),
      child: SizedBox(
        width: double.infinity,
        height: KSizes.buttonHeight,
        child: Button(
          variant: variant,
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }
}

/// Wrapper that provides SignupVM to the signup form
class _SignupFormScreen extends StatelessWidget {
  final SignupType signupType;
  final Map<String, dynamic> quizData;

  const _SignupFormScreen({required this.signupType, required this.quizData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignupVM(
        invitationRepo: context.read<InvitationsRepository>(),
        userRepo: context.read<UserRepository>(),
        organizationRepo: signupType == SignupType.provider
            ? context.read<OrganizationRepository>()
            : null,
        divisionRepo: signupType == SignupType.provider
            ? context.read<DivisionRepository>()
            : null,
        signupType: signupType,
        quizData: quizData,
      ),
      child: const _SignupFormContent(),
    );
  }
}

/// The actual signup form content
class _SignupFormContent extends StatelessWidget {
  const _SignupFormContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupVM>();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Your Account")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vm.greeting,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              if (vm.signupType == SignupType.provider)
                _InputField(label: "Full Name", controller: vm.nameController),
              _InputField(
                label: "Email Address",
                controller: vm.emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _InputField(
                label: "Password",
                controller: vm.passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Text(
                "Password must be at least 6 characters",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const Spacer(),
              _SubmitButton(
                isLoading: vm.isLoading,
                isValid: vm.isValid,
                onPressed: () => _handleCreateAccount(context, vm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreateAccount(BuildContext context, SignupVM vm) async {
    final success = await vm.createAccount();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Please check your email for verification.',
          ),
        ),
      );
      await context.read<AuthStateController>().reloadUser();
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Reusable text input field
class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Submit button with loading state
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isLoading,
    required this.isValid,
    required this.onPressed,
  });

  final bool isLoading;
  final bool isValid;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Button(
        variant: ButtonVariant.primary,
        onPressed: isLoading || !isValid ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text("Create Account"),
      ),
    );
  }
}
