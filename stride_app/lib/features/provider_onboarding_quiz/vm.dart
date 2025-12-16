import 'package:flutter/material.dart';

class ProviderOnboardingQuizVM extends ChangeNotifier {
  ProviderOnboardingQuizVM() {
    for (final controller in _allControllers) {
      controller.addListener(notifyListeners);
    }
  }

  final PageController pageController = PageController();

  int _currentPage = 0;
  int get currentPage => _currentPage;
  set currentPage(int value) {
    if (_currentPage != value) {
      _currentPage = value;
      notifyListeners();
    }
  }

  final int totalPages = 3;

  // Page 1: Organization Info
  final TextEditingController organizationNameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  // Page 2: Service Details
  String? _serviceType;
  String? get serviceType => _serviceType;
  set serviceType(String? value) {
    if (_serviceType != value) {
      _serviceType = value;
      notifyListeners();
    }
  }

  final Set<String> _servicesProvided = {};
  Set<String> get servicesProvided => _servicesProvided;
  void addServiceProvided(String value) {
    if (_servicesProvided.add(value)) notifyListeners();
  }
  void removeServiceProvided(String value) {
    if (_servicesProvided.remove(value)) notifyListeners();
  }

  final TextEditingController numberOfClientsController = TextEditingController();

  // Page 3: Goals & Expectations
  final Set<String> _goals = {};
  Set<String> get goals => _goals;
  void addGoal(String value) {
    if (_goals.add(value)) notifyListeners();
  }
  void removeGoal(String value) {
    if (_goals.remove(value)) notifyListeners();
  }

  final TextEditingController additionalInfoController = TextEditingController();

  List<TextEditingController> get _allControllers => [
        organizationNameController,
        roleController,
        numberOfClientsController,
        additionalInfoController,
      ];

  bool canProceed() {
    switch (currentPage) {
      case 0:
        return organizationNameController.text.isNotEmpty &&
            roleController.text.isNotEmpty;
      case 1:
        return serviceType != null &&
            servicesProvided.isNotEmpty &&
            numberOfClientsController.text.isNotEmpty;
      case 2:
        return goals.isNotEmpty;
      default:
        return false;
    }
  }

  void nextPage() {
    if (currentPage < totalPages - 1) {
      currentPage++;
      pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      currentPage--;
      pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  // Convert to Firebase format
  Map<String, List<String>> getAnswersMap() {
    return {
      'organization_info_question_organization_name': [organizationNameController.text],
      'organization_info_question_role': [roleController.text],
      'service_type_question': [serviceType ?? ''],
      'services_provided_question': servicesProvided.toList(),
      'number_of_clients_question': [numberOfClientsController.text],
      'provider_goals_question': goals.toList(),
      'additional_info_question': [additionalInfoController.text],
    };
  }

  Map<String, String> getQuestionsTextMap() {
    return {
      'organization_info_question_organization_name': 'Organization Information (organization name)',
      'organization_info_question_role': 'Organization Information (your role)',
      'service_type_question': 'What type of service do you provide?',
      'services_provided_question': 'What services do you provide? (select all that apply)',
      'number_of_clients_question': 'How many clients do you currently serve?',
      'provider_goals_question': 'What are your main goals using Stride? (select all that apply)',
      'additional_info_question': 'Any additional information you\'d like to share?',
    };
  }

  @override
  void dispose() {
    pageController.dispose();
    for (final controller in _allControllers) {
      controller.removeListener(notifyListeners);
      controller.dispose();
    }
    super.dispose();
  }
}