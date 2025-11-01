import 'package:flutter/material.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/models/division_m.dart';
import 'package:stride_core/repositories/division_repo.dart';

class DivisionsViewModel extends ChangeNotifier {
  final DivisionRepository _divisionRepo;
  final AuthStateController _authStateController;

  List<DivisionModel> _divisions = [];
  bool _isLoading = false;
  String? _errorMessage;

  DivisionsViewModel({
    required DivisionRepository divisionRepo,
    required AuthStateController authStateController,
  })  : _divisionRepo = divisionRepo,
        _authStateController = authStateController {
    loadDivisions();
  }

  List<DivisionModel> get divisions => _divisions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasDivisions => _divisions.isNotEmpty;

  // Store counts for each division
  Map<String, Map<String, int>> _divisionCounts = {};

  /// Get provider count for a specific division
  int getProviderCount(String divisionId) {
    return _divisionCounts[divisionId]?['providers'] ?? 0;
  }

  /// Get client count for a specific division
  int getClientCount(String divisionId) {
    return _divisionCounts[divisionId]?['clients'] ?? 0;
  }

  /// Load all divisions
  Future<void> loadDivisions({bool includeDeleted = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    print("here");
    print(_authStateController.user);

    try {
      _divisions = await _divisionRepo.getByOrganizationId(
          organizationId: _authStateController.user!.organizationId,
          includeDeleted: includeDeleted);

      // Load counts for all divisions
      if (_divisions.isNotEmpty) {
        final divisionIds = _divisions.map((d) => d.id).toList();
        _divisionCounts =
            await _divisionRepo.getCountsForDivisions(divisionIds);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _divisions = [];
      _divisionCounts = {};
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create new division
  Future<bool> createDivision(CreateDivisionDataModel data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newDivision = await _divisionRepo.create(data);
      _divisions.insert(0, newDivision);
      _divisionCounts[newDivision.id] = {'providers': 0, 'clients': 0};
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

  /// Update division
  Future<bool> updateDivision(
    String divisionId,
    UpdateDivisionDataModel data,
  ) async {
    _errorMessage = null;

    try {
      await _divisionRepo.update(divisionId, data);

      // Update local list
      final index = _divisions.indexWhere((d) => d.id == divisionId);
      if (index != -1) {
        // Reload the specific division to get updated data
        final updated = await _divisionRepo.getById(divisionId);
        if (updated != null) {
          _divisions[index] = updated;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Assign manager to division
  Future<bool> assignManager(String divisionId, String managerId) async {
    _errorMessage = null;

    try {
      await _divisionRepo.assignManager(divisionId, managerId);

      // Update local list
      final index = _divisions.indexWhere((d) => d.id == divisionId);
      if (index != -1) {
        final updated = await _divisionRepo.getById(divisionId);
        if (updated != null) {
          _divisions[index] = updated;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Soft delete division
  Future<bool> deleteDivision(String divisionId) async {
    _errorMessage = null;

    try {
      await _divisionRepo.softDelete(divisionId);

      // Remove from local list
      _divisions.removeWhere((d) => d.id == divisionId);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Restore soft deleted division
  Future<bool> restoreDivision(String divisionId) async {
    _errorMessage = null;

    try {
      await _divisionRepo.restore(divisionId);

      // Reload divisions to include restored one
      await loadDivisions();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh divisions list
  Future<void> refresh() async {
    await loadDivisions();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get division by ID from loaded list
  DivisionModel? getDivisionById(String divisionId) {
    try {
      return _divisions.firstWhere((d) => d.id == divisionId);
    } catch (e) {
      return null;
    }
  }

  /// Filter divisions by status
  List<DivisionModel> getDivisionsByStatus(String status) {
    return _divisions.where((d) => d.status == status).toList();
  }

  /// Get active divisions only
  List<DivisionModel> get activeDivisions {
    return getDivisionsByStatus('active');
  }

  /// Get deleted divisions only
  List<DivisionModel> get deletedDivisions {
    return getDivisionsByStatus('deleted');
  }
}
