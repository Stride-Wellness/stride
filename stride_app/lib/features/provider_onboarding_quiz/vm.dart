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

  final int totalPages = 2; // Fixed: was 3 but only 2 pages

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
    if (_servicesProvided.add(value)) {
      notifyListeners();
    }
  }
  
  void removeServiceProvided(String value) {
    if (_servicesProvided.remove(value)) {
      notifyListeners();
    }
  }

  final TextEditingController additionalInfoController = TextEditingController();

  List<TextEditingController> get _allControllers => [
        organizationNameController,
    roleController,
        additionalInfoController,
      ];

  bool canProceed() {
    switch (currentPage) {
      case 0:
        return organizationNameController.text.isNotEmpty &&
            roleController.text.isNotEmpty;
      case 1:
        return serviceType != null && servicesProvided.isNotEmpty;
      default:
        return false;
    }
  }

  void nextPage() {
    if (currentPage < totalPages - 1) {
      _currentPage++;
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
      _currentPage--;
      pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  Map<String, List<String>> getAnswersMap() {
    return {
      'organization_info_question_organization_name': [organizationNameController.text],
      'organization_info_question_role': [roleController.text],
      'service_type_question': [serviceType ?? ''],
      'services_provided_question': servicesProvided.toList(),
      'additional_info_question': [additionalInfoController.text],
    };
  }

  Map<String, String> getQuestionsTextMap() {
    return {
      'organization_info_question_organization_name': 'Organization Name',
      'organization_info_question_role': 'Your Role/Title',
      'service_type_question': 'How would you best describe your service?',
      'services_provided_question': 'What services do you provide?',
      'additional_info_question': 'Additional information',
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