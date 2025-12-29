import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/client_onboarding_quiz/v.dart';
import 'package:stride_app/features/client_onboarding_quiz/vm.dart';
import 'package:stride_app/features/provider_assisted_client_signup/vm.dart';
import 'package:stride_app/media/completion_checkmark_animation.dart';
import 'package:stride_app/media/new_client_animation.dart';
import 'package:stride_core/repositories/invitations_repo.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';

class ProviderAssistedClientSignupV extends StatelessWidget {
  const ProviderAssistedClientSignupV({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProviderAssistedClientSignupVM(
        invitationsRepo: context.read<InvitationsRepository>(),
      ),
      child: const _ProviderAssistedClientSignupVContent(),
    );
  }
}

class _ProviderAssistedClientSignupVContent extends StatelessWidget {
  const _ProviderAssistedClientSignupVContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderAssistedClientSignupVM>();
    return Scaffold(
      appBar: AppBar(title: const Text("Add a new Client")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const NewClientAnimation(),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.all(KPadding.large),
                child: Text(
                  vm.instructionText,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: Button(
                  variant: ButtonVariant.primary,
                  onPressed: () async {
                    final quizResult = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientOnboardingQuizView(
                          mode:
                              ClientOnboardingMode.providerAssistedRegistration,
                        ),
                      ),
                    );
                    if (quizResult != null) {
                      final code = await vm.createClientInvitation(quizResult);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              InvitationConfirmationPage(code: code),
                        ),
                      );
                    }
                  },
                  child: const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvitationConfirmationPage extends StatelessWidget {
  final int code;

  const InvitationConfirmationPage({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invitation Created"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              const CompletionCheckmarkAnimation(),
              const Spacer(flex: 2),
              const Text(
                "We've recorded your answers and saved the invitation.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "This invitation will remain valid for 1 week.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text(
                "Share this code with your client to finish onboarding:",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Spacer(flex: 3),
              SelectableText(
                code.toString(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 5),
              SizedBox(
                width: double.infinity,
                child: Button(
                  variant: ButtonVariant.primary,
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text("Return to Clients"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
