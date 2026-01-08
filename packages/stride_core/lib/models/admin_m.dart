import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminPrivilegeLevel { superAdmin, admin, moderator, readOnly, disabled }

AdminPrivilegeLevel _privilegeFrom(dynamic value) {
  if (value is int) {
    return AdminPrivilegeLevel.values
        .firstWhere((level) => level.index == value, orElse: () => AdminPrivilegeLevel.readOnly);
  }

  if (value is String) {
    final normalized = value.toLowerCase();
    return AdminPrivilegeLevel.values.firstWhere(
      (level) => level.name.toLowerCase() == normalized,
      orElse: () => AdminPrivilegeLevel.readOnly,
    );
  }

  return AdminPrivilegeLevel.readOnly;
}

DateTime _safeDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

class AdminModel {
  final String id;
  final String name;
  final AdminPrivilegeLevel privilege;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSignIn;

  AdminModel({
    required this.id,
    required this.name,
    required this.privilege,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastSignIn,
  });

  factory AdminModel.fromMap(Map<String, dynamic> data, String id) {
    return AdminModel(
      id: id,
      name: data['name'] ?? '',
      privilege: _privilegeFrom(data['privilege']),
      createdBy: data['createdBy'] ?? '',
      createdAt: _safeDate(data['createdAt']),
      updatedAt: _safeDate(data['updatedAt']),
      lastSignIn: data['lastSignIn'] != null ? _safeDate(data['lastSignIn']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'privilege': privilege.index,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (lastSignIn != null) 'lastSignIn': Timestamp.fromDate(lastSignIn!),
    };
  }
}

class CreateAdminDataModel {
  final String email;
  final String password;
  final String name;
  final AdminPrivilegeLevel privilege;

  CreateAdminDataModel({
    required this.email,
    required this.password,
    required this.name,
    this.privilege = AdminPrivilegeLevel.readOnly,
  });
}

class UpdateAdminDataModel {
  final String userId;
  final String? name;
  final AdminPrivilegeLevel? privilege;

  UpdateAdminDataModel({
    required this.userId,
    this.name,
    this.privilege,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'userId': userId};
    if (name != null) map['name'] = name;
    if (privilege != null) map['privilege'] = privilege!.index;
    return map;
  }
}
