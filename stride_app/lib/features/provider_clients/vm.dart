import 'package:flutter/material.dart';
import 'package:stride_core/models/invitation_m.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/repositories/assignments_repo.dart';
import 'package:stride_core/repositories/invitations_repo.dart';

class ProviderClientsListVM extends ChangeNotifier {
  final AssignmentsRepository _assignmentsRepo;
  final InvitationsRepository _invitationsRepo;

  List<ClientUserModel> _clients = [];
  List<InvitationModel> _invitations = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProviderClientsListVM({
    required InvitationsRepository invitationsRepo,
    required AssignmentsRepository assignmentsRepo,
  })
    : _assignmentsRepo = assignmentsRepo,
       _invitationsRepo = invitationsRepo {
    loadClients();
    loadInvitations();
  }

  List<ClientUserModel> get clients => _clients;
  List<InvitationModel> get invitations => _invitations;
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

  Future<void> loadInvitations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invitations = await _invitationsRepo.getInvitationsByUser();
    } catch (e) {
      _errorMessage = e.toString();
      _invitations = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadClients();
    await loadInvitations();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}