import 'package:cloud_firestore/cloud_firestore.dart';

class DivisionSettingsModel {
  final Map<String, dynamic> data;

  DivisionSettingsModel(this.data);

  factory DivisionSettingsModel.fromMap(Map<String, dynamic> map) {
    return DivisionSettingsModel(map);
  }

  Map<String, dynamic> toMap() => data;
}


class DivisionModel {
  final String id;
  final String organizationId;
  final String name;
  final String? managerId;
  final String divisionType; // 'retirement_home', 'homecare_provider'
  final DivisionSettingsModel settings;
  final String status; // 'active', 'inactive', 'deleted'
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DivisionModel({
    required this.id,
    required this.organizationId,
    required this.name,
    this.managerId,
    required this.divisionType,
    required this.settings,
    required this.status,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DivisionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DivisionModel(
      id: doc.id,
      organizationId: data['organizationId'] ?? '',
      name: data['name'] ?? '',
      managerId: data['managerId'],
      divisionType: data['divisionType'] ?? 'retirement_home',
      settings: DivisionSettingsModel.fromMap(data['settings'] ?? {}),
      status: data['status'] ?? 'active',
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'name': name,
      'managerId': managerId,
      'divisionType': divisionType,
      'settings': settings.toMap(),
      'status': status,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class CreateDivisionDataModel {
  final String organizationId;
  final String name;
  final String? managerId;
  final String divisionType;
  final DivisionSettingsModel? settings;

  CreateDivisionDataModel({
    required this.organizationId,
    required this.name,
    this.managerId,
    required this.divisionType,
    this.settings,
  });
}

class UpdateDivisionDataModel {
  final String? name;
  final String? managerId;
  final String? divisionType;
  final DivisionSettingsModel? settings;
  final String? status;
  final DateTime? deletedAt;

  UpdateDivisionDataModel({
    this.name,
    this.managerId,
    this.divisionType,
    this.settings,
    this.status,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (managerId != null) map['managerId'] = managerId;
    if (divisionType != null) map['divisionType'] = divisionType;
    if (settings != null) map['settings'] = settings!.toMap();
    if (status != null) map['status'] = status;
    if (deletedAt != null) {
      map['deletedAt'] = Timestamp.fromDate(deletedAt!);
    }
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }
}