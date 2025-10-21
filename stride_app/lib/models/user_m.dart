import 'package:cloud_firestore/cloud_firestore.dart';

// Enums
enum EmployeeRole { psw, lw, admin, manager }

enum UserType { employee, client }

enum UserStatus { active, inactive, pending, deleted }

enum Mobility { independent, cane, walker, wheelchair }

// Helper Classes
class EmergencyContactModel {
  final String name;
  final String phone;
  final String relationship;

  EmergencyContactModel({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  factory EmergencyContactModel.fromMap(Map<String, dynamic> data) {
    return EmergencyContactModel(
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      relationship: data['relationship'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'relationship': relationship};
  }
}

class MedicalInfoModel {
  final List<String> conditions;
  final List<String> medications;
  final Mobility mobility;
  final String notes;
  final Map<String, dynamic> additionalInfo;

  MedicalInfoModel({
    required this.conditions,
    required this.medications,
    required this.mobility,
    required this.notes,
    Map<String, dynamic>? additionalInfo,
  }) : additionalInfo = additionalInfo ?? {};

  factory MedicalInfoModel.fromMap(Map<String, dynamic> data) {
    return MedicalInfoModel(
      conditions: List<String>.from(data['conditions'] ?? []),
      medications: List<String>.from(data['medications'] ?? []),
      mobility: Mobility.values.firstWhere(
        (e) => e.name == data['mobility'],
        orElse: () => Mobility.independent,
      ),
      notes: data['notes'] ?? '',
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conditions': conditions,
      'medications': medications,
      'mobility': mobility.name,
      'notes': notes,
      'additionalInfo': additionalInfo,
    };
  }
}

class ClientProfileModel {
  final String? phone;
  final String? dateOfBirth;
  final EmergencyContactModel? emergencyContact;
  final MedicalInfoModel? medicalInfo;
  final Map<String, dynamic> additionalInfo;

  ClientProfileModel({
    this.phone,
    this.dateOfBirth,
    this.emergencyContact,
    this.medicalInfo,
    Map<String, dynamic>? additionalInfo,
  }) : additionalInfo = additionalInfo ?? {};

  factory ClientProfileModel.fromMap(Map<String, dynamic> data) {
    return ClientProfileModel(
      phone: data['phone'],
      dateOfBirth: data['dateOfBirth'],
      emergencyContact: data['emergencyContact'] != null
          ? EmergencyContactModel.fromMap(data['emergencyContact'])
          : null,
      medicalInfo: data['medicalInfo'] != null
          ? MedicalInfoModel.fromMap(data['medicalInfo'])
          : null,
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'emergencyContact': emergencyContact?.toMap(),
      'medicalInfo': medicalInfo?.toMap(),
      'additionalInfo': additionalInfo,
    };
  }
}

// Base User class
abstract class BaseUserModel {
  final String id;
  final String email;
  final String name;
  final String organizationId;
  final String divisionId;
  final UserStatus status;
  final DateTime? lastLoginAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseUserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.organizationId,
    required this.divisionId,
    required this.status,
    this.lastLoginAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toBaseMap() {
    return {
      'email': email,
      'name': name,
      'organizationId': organizationId,
      'divisionId': divisionId,
      'status': status.name,
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Abstract method that must be implemented by subclasses
  Map<String, dynamic> toMap();

  static DateTime _timestampToDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }

  static BaseUserDataModel baseFromMap(Map<String, dynamic> data, String id) {
    return BaseUserDataModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      organizationId: data['organizationId'] ?? '',
      divisionId: data['divisionId'] ?? '',
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.active,
      ),
      lastLoginAt: data['lastLoginAt'] != null
          ? _timestampToDate(data['lastLoginAt'])
          : null,
      deletedAt: data['deletedAt'] != null
          ? _timestampToDate(data['deletedAt'])
          : null,
      createdAt: _timestampToDate(data['createdAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }
}

// Helper class for base data
class BaseUserDataModel {
  final String id;
  final String email;
  final String name;
  final String organizationId;
  final String divisionId;
  final UserStatus status;
  final DateTime? lastLoginAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseUserDataModel({
    required this.id,
    required this.email,
    required this.name,
    required this.organizationId,
    required this.divisionId,
    required this.status,
    this.lastLoginAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}

// Employee User
class EmployeeUserModel extends BaseUserModel {
  final UserType type = UserType.employee;
  final List<EmployeeRole> employeeRole;
  final Map<String, dynamic> profile;

  EmployeeUserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.organizationId,
    required super.divisionId,
    required super.status,
    super.lastLoginAt,
    super.deletedAt,
    required super.createdAt,
    required super.updatedAt,
    required this.employeeRole,
    Map<String, dynamic>? profile,
  }) : profile = profile ?? {};

  factory EmployeeUserModel.fromMap(Map<String, dynamic> data, String id) {
    final base = BaseUserModel.baseFromMap(data, id);
    return EmployeeUserModel(
      id: base.id,
      email: base.email,
      name: base.name,
      organizationId: base.organizationId,
      divisionId: base.divisionId,
      status: base.status,
      lastLoginAt: base.lastLoginAt,
      deletedAt: base.deletedAt,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      employeeRole:
          (data['employeeRole'] as List<dynamic>?)
              ?.map(
                (role) => EmployeeRole.values.firstWhere(
                  (e) => e.name == role,
                  orElse: () => EmployeeRole.psw,
                ),
              )
              .toList() ??
          [],
      profile: Map<String, dynamic>.from(data['profile'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...toBaseMap(),
      'type': type.name,
      'employeeRole': employeeRole.map((role) => role.name).toList(),
      'profile': profile,
    };
  }
}

// Client User
class ClientUserModel extends BaseUserModel {
  final UserType type = UserType.client;
  final ClientProfileModel profile;

  ClientUserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.organizationId,
    required super.divisionId,
    required super.status,
    super.lastLoginAt,
    super.deletedAt,
    required super.createdAt,
    required super.updatedAt,
    ClientProfileModel? profile,
  }) : profile = profile ?? ClientProfileModel();

  factory ClientUserModel.fromMap(Map<String, dynamic> data, String id) {
    final base = BaseUserModel.baseFromMap(data, id);
    return ClientUserModel(
      id: base.id,
      email: base.email,
      name: base.name,
      organizationId: base.organizationId,
      divisionId: base.divisionId,
      status: base.status,
      lastLoginAt: base.lastLoginAt,
      deletedAt: base.deletedAt,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      profile: data['profile'] != null
          ? ClientProfileModel.fromMap(data['profile'])
          : ClientProfileModel(),
    );
  }

  Map<String, dynamic> toMap() {
    return {...toBaseMap(), 'type': type.name, 'profile': profile.toMap()};
  }
}

// Union type for User
class UserModel {
  final BaseUserModel _user;

  UserModel._(this._user);

  factory UserModel.employee(EmployeeUserModel user) => UserModel._(user);
  factory UserModel.client(ClientUserModel user) => UserModel._(user);

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    final type = UserType.values.firstWhere(
      (e) => e.name == data['type'],
      orElse: () => UserType.client,
    );

    if (type == UserType.employee) {
      return UserModel.employee(EmployeeUserModel.fromMap(data, id));
    } else {
      return UserModel.client(ClientUserModel.fromMap(data, id));
    }
  }

  // Getters
  String get id => _user.id;
  String get email => _user.email;
  String get name => _user.name;
  String get organizationId => _user.organizationId;
  String get divisionId => _user.divisionId;
  UserStatus get status => _user.status;
  DateTime? get lastLoginAt => _user.lastLoginAt;
  DateTime? get deletedAt => _user.deletedAt;
  DateTime get createdAt => _user.createdAt;
  DateTime get updatedAt => _user.updatedAt;

  UserType get type {
    if (_user is EmployeeUserModel) return UserType.employee;
    return UserType.client;
  }

  // Type checking
  bool get isEmployee => _user is EmployeeUserModel;
  bool get isClient => _user is ClientUserModel;

  // Safe casting
  EmployeeUserModel? get asEmployee =>
      _user is EmployeeUserModel ? _user : null;
  ClientUserModel? get asClient => _user is ClientUserModel ? _user : null;

  Map<String, dynamic> toMap() {
    return _user.toMap();
  }
}

// Create Data classes
class CreateEmployeeUserDataModel {
  final String id;
  final String email;
  final String name;
  final String organizationId;
  final String divisionId;
  final List<EmployeeRole> employeeRole;
  final Map<String, dynamic>? profile;

  CreateEmployeeUserDataModel({
    required this.id,
    required this.email,
    required this.name,
    required this.organizationId,
    required this.divisionId,
    required this.employeeRole,
    this.profile,
  });
}

class CreateClientUserDataModel {
  final String id;
  final String email;
  final String name;
  final String organizationId;
  final String divisionId;
  final ClientProfileModel? profile;

  CreateClientUserDataModel({
    required this.id,
    required this.email,
    required this.name,
    required this.organizationId,
    required this.divisionId,
    this.profile,
  });
}

// Update Data classes
class UpdateEmployeeUserDataModel {
  final String? email;
  final String? name;
  final String? divisionId;
  final List<EmployeeRole>? employeeRole;
  final Map<String, dynamic>? profile;
  final UserStatus? status;
  final DateTime? lastLoginAt;
  final DateTime? deletedAt;

  UpdateEmployeeUserDataModel({
    this.email,
    this.name,
    this.divisionId,
    this.employeeRole,
    this.profile,
    this.status,
    this.lastLoginAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (email != null) map['email'] = email;
    if (name != null) map['name'] = name;
    if (divisionId != null) map['divisionId'] = divisionId;
    if (employeeRole != null)
      map['employeeRole'] = employeeRole!.map((e) => e.name).toList();
    if (profile != null) map['profile'] = profile;
    if (status != null) map['status'] = status!.name;
    if (lastLoginAt != null)
      map['lastLoginAt'] = Timestamp.fromDate(lastLoginAt!);
    if (deletedAt != null) map['deletedAt'] = Timestamp.fromDate(deletedAt!);
    return map;
  }
}

class UpdateClientUserDataModel {
  final String? email;
  final String? name;
  final String? divisionId;
  final ClientProfileModel? profile;
  final UserStatus? status;
  final DateTime? lastLoginAt;
  final DateTime? deletedAt;

  UpdateClientUserDataModel({
    this.email,
    this.name,
    this.divisionId,
    this.profile,
    this.status,
    this.lastLoginAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (email != null) map['email'] = email;
    if (name != null) map['name'] = name;
    if (divisionId != null) map['divisionId'] = divisionId;
    if (profile != null) map['profile'] = profile!.toMap();
    if (status != null) map['status'] = status!.name;
    if (lastLoginAt != null)
      map['lastLoginAt'] = Timestamp.fromDate(lastLoginAt!);
    if (deletedAt != null) map['deletedAt'] = Timestamp.fromDate(deletedAt!);
    return map;
  }
}
