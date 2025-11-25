import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/exercise/vm.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/repositories/assignments_repo.dart';

get providerClientsVMProvider => ChangeNotifierProvider(
  create: (context) => ProviderClientsListVM(
    assignmentsRepo: context.read<AssignmentsRepository>(),
    exerciseVM: context.read<ExerciseVM>(),
  ),
);

class ProviderClientsListVM extends ChangeNotifier {
  final AssignmentsRepository _assignmentsRepo;
  final ExerciseVM _exerciseVM;

  List<ClientUserModel> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProviderClientsListVM({
    required AssignmentsRepository assignmentsRepo,
    required ExerciseVM exerciseVM,
  }) : _assignmentsRepo = assignmentsRepo,
       _exerciseVM = exerciseVM {
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

  void onClientCardTap(String clientId) {
    _exerciseVM.clientId = clientId;
    _exerciseVM.initialize();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}