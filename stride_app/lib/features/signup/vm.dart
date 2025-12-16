import 'package:flutter/material.dart';
import 'package:stride_core/models/division_m.dart';
import 'package:stride_core/models/organization_m.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/repositories/division_repo.dart';
import 'package:stride_core/repositories/organization_repo.dart';
import 'package:stride_core/repositories/user_repo.dart';

enum SignupType { client, provider }

class SignupVM extends ChangeNotifier {
  final UserRepository userRepo;
  final OrganizationRepository? organizationRepo;
  final DivisionRepository? divisionRepo;
  final SignupType signupType;
  final Map<String, dynamic>? quizData;

  SignupVM({
    required this.userRepo,
    required this.signupType,
    this.organizationRepo,
    this.divisionRepo,
    this.quizData,
  });

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool get isValid {
    final hasName = signupType == SignupType.client || nameController.text.isNotEmpty;
    return hasName &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        passwordController.text.length >= 6;
  }

  String get greeting {
    if (signupType == SignupType.client && quizData?['name'] != null) {
      return "Almost done, ${quizData!['name']}!";
    }
    return signupType == SignupType.client ? "Create Your Account" : "Create Provider Account";
  }

  Future<bool> createAccount() async {
    if (!isValid) {
      _errorMessage = "Please fill in all fields correctly";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (signupType == SignupType.client) {
        await userRepo.createClientFromOnboarding(
          name: quizData!['name'],
          email: emailController.text,
          password: passwordController.text,
          quizQuestions: quizData!['questions'],
          quizAnswers: quizData!['answers'],
          sendEmailVerification: true,
        );
      } else {
        final orgName = (quizData?['answers'] as Map<String, List<String>>?)
            ?['organization_info_question_organization_name']?.first ?? 'Organization';

        final org = await organizationRepo!.create(CreateOrganizationDataModel(
          name: orgName,
          totalSeats: 100,
          stripeUserId: "",
        ));

        final div = await divisionRepo!.create(CreateDivisionDataModel(
          name: "default",
          organizationId: org.id,
          divisionType: 'homecare_provider',
        ));

        final user = await userRepo.createProvider(
          email: emailController.text,
          password: passwordController.text,
          name: nameController.text,
          organizationId: org.id,
          divisionId: div.id,
          providerRole: [ProviderRole.admin, ProviderRole.manager, ProviderRole.psw],
          sendEmailVerification: true,
        );

        await divisionRepo!.update(div.id, UpdateDivisionDataModel(managerId: user.id));
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
