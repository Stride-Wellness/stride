import 'package:flutter/material.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/repositories/assignments_repo.dart';
import 'package:stride_core/repositories/user_repo.dart';

class UsersViewModel extends ChangeNotifier {
  final UserRepository _userRepo;
  final AssignmentsRepository _assignmentsRepo;

  List<UserModel> _allUsers = [];
  List<ProviderUserModel> _employees = [];
  List<ClientUserModel> _clients = [];
  
  // Assignment tracking
  Map<String, String> _clientAssignments = {}; // clientId -> therapistId
  Map<String, ProviderUserModel> _employeesMap = {}; // therapistId -> ProviderUserModel
  
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  UsersViewModel({
    required UserRepository userRepo,
    required AssignmentsRepository assignmentsRepo,
  }) : _userRepo = userRepo,
       _assignmentsRepo = assignmentsRepo {
    loadUsers();
  }

  // Getters
  List<ProviderUserModel> get employees => _filteredEmployees;
  List<ClientUserModel> get clients => _filteredClients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get employeeCount => _employees.length;
  int get clientCount => _clients.length;
  bool get hasEmployees => _employees.isNotEmpty;
  bool get hasClients => _clients.isNotEmpty;

  List<ProviderUserModel> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    final query = _searchQuery.toLowerCase();
    return _employees.where((e) =>
      e.name.toLowerCase().contains(query) ||
      e.email.toLowerCase().contains(query)
    ).toList();
  }

  List<ClientUserModel> get _filteredClients {
    if (_searchQuery.isEmpty) return _clients;
    final query = _searchQuery.toLowerCase();
    return _clients.where((c) =>
      c.name.toLowerCase().contains(query) ||
      c.email.toLowerCase().contains(query)
    ).toList();
  }

  /// Get assigned therapist name for a client
  String getAssignedProviderName(String clientId) {
    final therapistId = _clientAssignments[clientId];
    if (therapistId == null) return 'Unassigned';
    return _employeesMap[therapistId]?.name ?? 'Unknown';
  }

  /// Get client count for a therapist
  int getClientCountForProvider(String therapistId) {
    return _clientAssignments.values.where((id) => id == therapistId).length;
  }

  /// Load all users and assignments
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allUsers = await _userRepo.getByOrganization();
      _filterUsers();
      _buildEmployeesMap();
      await _loadAssignments();
    } catch (e) {
      _errorMessage = e.toString();
      _allUsers = [];
      _employees = [];
      _clients = [];
      _clientAssignments = {};
      _employeesMap = {};
    }
    _isLoading = false;
    notifyListeners();
  }

  void _filterUsers() {
    _employees = [];
    _clients = [];
    for (final user in _allUsers) {
      if (user.type == UserType.employee) {
        final employee = user.asEmployee;
        if (employee != null) _employees.add(employee);
      } else if (user.type == UserType.client) {
        final client = user.asClient;
        if (client != null) _clients.add(client);
      }
    }
  }

  void _buildEmployeesMap() {
    _employeesMap = {for (var e in _employees) e.id: e};
  }

  Future<void> _loadAssignments() async {
    try {
      _clientAssignments = {};
      
      // Get assignments for all employees
      for (final employee in _employees) {
        final clients = await _assignmentsRepo.getClients_(employee.id);
        for (final client in clients) {
          _clientAssignments[client.id] = employee.id;
        }
      }
    } catch (e) {
      print('Error loading assignments: $e');
      _clientAssignments = {};
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> refresh() => loadUsers();

  Future<bool> deleteUser(String userId) async {
    _errorMessage = null;
    try {
      final success = await _userRepo.hardDeleteFirestore_(userId);
      if (success) {
        _allUsers.removeWhere((u) => u.id == userId);
        _employees.removeWhere((u) => u.id == userId);
        _clients.removeWhere((u) => u.id == userId);
        _employeesMap.remove(userId);
        _clientAssignments.remove(userId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}