import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/controllers/auth_state_controller.dart';
import 'package:stride_app/features/client_onboarding_quiz/v.dart';
import 'package:stride_app/features/client_onboarding_quiz/vm.dart';
import 'package:stride_app/features/provider_onboarding_quiz/v.dart';
import 'package:stride_app/features/signup/vm.dart';
import 'package:stride_core/repositories/division_repo.dart';
import 'package:stride_core/repositories/organization_repo.dart';
import 'package:stride_core/repositories/user_repo.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  SignupVM? _vm;
  Map<String, dynamic>? _quizData;
  SignupType? _signupType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOptionsPage());
  }

  Future<void> _showOptionsPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _GetStartedPageView()),
    );

    if (result == null && mounted) {
      Navigator.pop(context);
      return;
    }

    // result is a Map with 'type' and 'quizData'
    setState(() {
      _signupType = result['type'] as SignupType;
      _quizData = result['quizData'];
      _vm = SignupVM(
        userRepo: context.read<UserRepository>(),
        organizationRepo: _signupType == SignupType.provider
            ? context.read<OrganizationRepository>()
            : null,
        divisionRepo: _signupType == SignupType.provider
            ? context.read<DivisionRepository>()
            : null,
        signupType: _signupType!,
        quizData: _quizData,
      );
    });
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_vm == null || _quizData == null || _signupType == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: _vm!,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text("Create Your Account")),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KPadding.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vm!.greeting,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                if (_signupType == SignupType.provider)
                  _buildTextField("Full Name", _vm!.nameController),

                _buildTextField(
                  "Email Address",
                  _vm!.emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  "Password",
                  _vm!.passwordController,
                  obscureText: true,
                ),

                const SizedBox(height: 8),
                Text(
                  "Password must be at least 6 characters",
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                if (_vm!.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _vm!.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: Button(
                    variant: ButtonVariant.primary,
                    onPressed: _vm!.isLoading || !_vm!.isValid
                        ? null
                        : _handleCreateAccount,
                    child: _vm!.isLoading
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
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

  Future<void> _handleCreateAccount() async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await _vm!.createAccount();

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Please check your email for verification.',
          ),
        ),
      );
      if (mounted) {
        await context.read<AuthStateController>().reloadUser();
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else if (_vm!.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_vm!.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _GetStartedPageView extends StatelessWidget {
  const _GetStartedPageView();

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
              Expanded(child: Container()),
              _LocalButton(
                text: "I am using Stride for myself.",
                onPressed: () async {
                  final quizData = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientOnboardingQuizView(
                        mode: ClientOnboardingMode.clientSelfRegistration,
                      ),
                    ),
                  );

                  if (quizData != null && context.mounted) {
                    Navigator.pop(context, {
                      'type': SignupType.client,
                      'quizData': quizData,
                    });
                  }
                },
                variant: ButtonVariant.primary,
              ),
              _LocalButton(
                text: "I am helping other people.",
                onPressed: () async {
                  final quizData = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProviderOnboardingQuizView(),
                    ),
                  );

                  if (quizData != null && context.mounted) {
                    Navigator.pop(context, {
                      'type': SignupType.provider,
                      'quizData': quizData,
                    });
                  }
                },
                variant: ButtonVariant.secondary,
              ),
              _LocalButton(
                text: "I have a code.",
                onPressed: () {
                  // TODO: Implement code entry
                },
                variant: ButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalButton extends StatelessWidget {
  const _LocalButton({
    required this.text,
    required this.onPressed,
    required this.variant,
  });

  final String text;
  final VoidCallback onPressed;
  final ButtonVariant variant;

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
