import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/signin/vm.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_core/models/question_node_m.dart';
import 'package:stride_ui/widgets/button.dart';
import 'package:stride_ui/widgets/list_options.dart';

class SignInScreenView extends StatelessWidget {
  const SignInScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final signInVM = context.watch<SignInVM>();
    final navigator = Navigator.of(context);

    final questions = [
      QuestionOption("Email", QuestionType.input, fieldKey: "email"),
      QuestionOption("Password", QuestionType.input, fieldKey: "password"),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
              // Show error message if any
              if (signInVM.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          signInVM.errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              ListOptionsWidget(
                options: questions,
                isMultiField: true,
                maxSelected: 1,
                minSelected: 1,
                onSelectionChanged: (value) {
                  signInVM.updateCredentials(value);
                },
              ),
              
              const SizedBox(height: 16),
              
              // Forgot password button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: signInVM.isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await signInVM.sendPasswordReset();
                          
                          if (signInVM.errorMessage == null) {
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

              const SizedBox(height: 24),

              // Sign in button
              SizedBox(
                width: double.infinity,
                height: KSizes.buttonHeight,
                child: Button(
                  variant: ButtonVariant.primary,
                  onPressed: signInVM.isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          
                          final success = await signInVM.signIn();
          
                          
                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Signed in successfully!')),
                            );
                            navigator.pushNamedAndRemoveUntil(
                              '/home',
                              (route) => false,
                            );
                          } else {
                            if (signInVM.errorMessage != null) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(signInVM.errorMessage!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: signInVM.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Sign In"),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Create account link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () {
                      navigator.pushNamed('/create-account');
                    },
                    child: const Text('Create Account'),
                  ),
                ],
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}