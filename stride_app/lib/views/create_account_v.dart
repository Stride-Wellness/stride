import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/constants/layout.dart';
import 'package:stride_app/models/question_node_m.dart';
import 'package:stride_app/view_models/auth_state_vm.dart';
import 'package:stride_app/view_models/create_account_vm.dart';
import 'package:stride_app/widgets/button.dart';
import 'package:stride_app/widgets/list_options.dart';

class CreateAccountScreenView extends StatelessWidget {
  const CreateAccountScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final createAccountVM = context.watch<CreateAccountViewModel>();
    final navigator = Navigator.of(context);

    final questions = [
      QuestionOption("Email", QuestionType.input, fieldKey: "email"),
      QuestionOption("Full Name", QuestionType.input, fieldKey: "full_name"),
      QuestionOption("Organization Name (don't have one? Just use yours.)", QuestionType.input, fieldKey: "organization_name"),
      QuestionOption("Password", QuestionType.input, fieldKey: "password"),
      QuestionOption("Confirm Password", QuestionType.input, fieldKey: "confirm_password"),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            children: [
              const Text(
                "Account Information",
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 100),
              // Show error message if any
              if (createAccountVM.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    createAccountVM.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ListOptionsWidget(
                options: questions,
                isMultiField: true,
                maxSelected: 1,
                minSelected: 1,
                onSelectionChanged: (value) {
                  createAccountVM.updateAnswers(value);
                },
              ),
              const SizedBox(height: 50),
              

              Expanded(child: Container()),
              SizedBox(
                width: double.infinity,
                height: KSizes.buttonHeight,
                child: Button(
                  varient: ButtonVarient.primary,
                  onPressed: createAccountVM.isLoading
                      ? null
                      : () async {
                          // Capture context before async gap
                          final messenger = ScaffoldMessenger.of(context);
                          
                          final user = await createAccountVM.createAccount();
                          
                          if (user != null) {
                            // Success - navigate or show success
                            messenger.showSnackBar(
                              SnackBar(content: Text('Account created for ${user.name}')),
                            );
                            // Optionally navigate to home
                            navigator.pushNamedAndRemoveUntil('/account', (route) => false);
                          } else {
                            // Error is already set in errorMessage and displayed above
                            // Optionally show additional feedback
                            if (createAccountVM.errorMessage != null) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(createAccountVM.errorMessage!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: createAccountVM.isLoading
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
    );
  }
}