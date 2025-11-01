import 'package:flutter/material.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/repositories/assignments_repo.dart';

class ProviderClientsListVM extends ChangeNotifier {
  final AssignmentsRepository _assignmentsRepo;

  List<ClientUserModel> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProviderClientsListVM({
    required AssignmentsRepository assignmentsRepo,
  }) : _assignmentsRepo = assignmentsRepo {
    loadClients();
  }

  List<ClientUserModel> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasClients => _clients.isNotEmpty;

  Future<void> loadClients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clients = await _assignmentsRepo.getClients();
    } catch (e) {
      _errorMessage = e.toString();
      _clients = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadClients();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}