import 'package:flutter/material.dart';
import 'package:stride_app/models/division_m.dart';
import 'package:stride_app/models/organization_m.dart';
import 'package:stride_app/models/user_m.dart';
import 'package:stride_app/repositories/division_repo.dart';
import 'package:stride_app/repositories/organization_repo.dart';
import 'package:stride_app/repositories/user_repo.dart';
import 'package:stride_app/services/auth_service.dart';

class CreateAccountViewModel extends ChangeNotifier {
  final OrganizationRepository organizationRepo;
  final UserRepository userRepo;
  final DivisionRepository divisionRepo;
  final AuthService authService;

  CreateAccountViewModel({
    required this.organizationRepo,
    required this.divisionRepo,
    required this.userRepo,
    required this.authService,
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

  Future<EmployeeUserModel?> createAccount() async {
    if (!isValid) {
      _errorMessage = "Please fill in all fields correctly";
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Create Firebase Auth account
      final credential = await authService.signUpWithEmailAndPassword(
        email: accountInfo["email"]!,
        password: accountInfo["password"]!,
      );

      if (credential.user == null) {
        throw Exception("Failed to create authentication account");
      }

      // Step 2: Send email verification
      await authService.sendEmailVerification();

      // Step 3: Create organization in Firestore
      final org = await organizationRepo.create(CreateOrganizationDataModel(
        name: accountInfo["organization_name"]!,
        totalSeats: 100,
        stripeUserId: "",
      ));

      // Step 4: Create division
      final div = await divisionRepo.create(CreateDivisionDataModel(
        name: "default",
        organizationId: org.id, 
        divisionType: 'homecare_provider',
      ));

      // Step 5: Create user document in Firestore with Firebase Auth UID
      final user = await userRepo.createEmployee(
        CreateEmployeeUserDataModel(
          id: credential.user!.uid, // Use Firebase Auth UID
          email: accountInfo["email"]!,
          name: accountInfo["full_name"]!,
          organizationId: org.id,
          divisionId: div.id,
          employeeRole: [EmployeeRole.admin, EmployeeRole.manager, EmployeeRole.psw],
        ),
      );

      // Step 6: Assign user as division manager
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
      
      // If Firestore operations fail, delete the auth account to prevent orphaned accounts
      try {
        await authService.deleteAccount();
      } catch (deleteError) {
        print('Failed to cleanup auth account: $deleteError');
      }
      
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}