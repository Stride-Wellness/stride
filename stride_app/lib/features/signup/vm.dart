import 'package:flutter/material.dart';
import 'package:stride_core/models/division_m.dart';
import 'package:stride_core/models/organization_m.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/repositories/division_repo.dart';
import 'package:stride_core/repositories/organization_repo.dart';
import 'package:stride_core/repositories/user_repo.dart';


class CreateAccountVM extends ChangeNotifier {
  final OrganizationRepository organizationRepo;
  final UserRepository userRepo;
  final DivisionRepository divisionRepo;

  CreateAccountVM({
    required this.organizationRepo,
    required this.divisionRepo,
    required this.userRepo,
  });
  
  Map<String, String> accountInfo = {
    "email": "",
    "full_name": "",
    "organization_name": "",
    "password": "",
    "confirm_password": "",
  };

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isValid {
    return accountInfo.values.every((value) => value.isNotEmpty) &&
           accountInfo["password"] == accountInfo["confirm_password"] &&
           accountInfo["password"]!.length >= 6;
  }

  void updateAnswers(List<String> selected) {
    for (String entry in selected) {
      if (entry.contains(':')) {
        List<String> parts = entry.split(':');
        if (parts.length == 2) {
          String fieldKey = parts[0];
          String value = parts[1];
          accountInfo[fieldKey] = value;
        }
      }
    }
    notifyListeners();
  }

  Future<ProviderUserModel?> createAccount() async {
    if (!isValid) {
      _errorMessage = "Please fill in all fields correctly";
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Create organization in Firestore
      final org = await organizationRepo.create(CreateOrganizationDataModel(
        name: accountInfo["organization_name"]!,
        totalSeats: 100,
        stripeUserId: "",
      ));

      // Step 2: Create division
      final div = await divisionRepo.create(CreateDivisionDataModel(
        name: "default",
        organizationId: org.id, 
        divisionType: 'homecare_provider',
      ));

      // Step 3: Create provider account with auth (using high-level method)
      final user = await userRepo.createProvider(
        email: accountInfo["email"]!,
        password: accountInfo["password"]!,
        name: accountInfo["full_name"]!,
        organizationId: org.id,
        divisionId: div.id,
        providerRole: [
          ProviderRole.admin,
          ProviderRole.manager,
          ProviderRole.psw,
        ],
        sendEmailVerification: true,
      );

      // Step 4: Assign user as division manager
      await divisionRepo.update(div.id, UpdateDivisionDataModel(
        managerId: user.id,
      ));

      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}