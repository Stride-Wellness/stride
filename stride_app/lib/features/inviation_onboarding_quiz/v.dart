import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/inviation_onboarding_quiz/vm.dart';
import 'package:stride_app/features/shared/widgets/async_button.dart';
import 'package:stride_core/repositories/invitations_repo.dart';
import 'package:stride_ui/constants/layout.dart';

class InvitationCodeInputScreen extends StatelessWidget {
  const InvitationCodeInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InvitationOnboardingQuizVM(
        invitationsRepo: context.read<InvitationsRepository>(),
      ),
      child: const _InvitationCodeInputContent(),
    );
  }
}

class _InvitationCodeInputContent extends StatelessWidget {
  const _InvitationCodeInputContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InvitationOnboardingQuizVM>();

    return Scaffold(
      appBar: AppBar(title: const Text("Enter Invitation Code")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: vm.codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Invitation Code",
                  border: OutlineInputBorder(),
                  hintText: "Enter 6-digit code",
                ),
                maxLength: 6,
              ),
              const SizedBox(height: 16),
              if (vm.errorMessage != null) ...[
                Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              AsyncButton(
                label: "Submit",
                isLoading: vm.isLoading,
                onPressed: vm.isLoading
                    ? null
                    : () => _handleSubmit(context, vm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    InvitationOnboardingQuizVM vm,
  ) async {
    if (vm.codeController.text.isEmpty) {
      return;
    }

    final quizData = await vm.getQuizData();

    if (quizData != null && context.mounted) {
      Navigator.pop(context, quizData);
    }
  }
}
