import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationSettingsModel {
  final Map<String, dynamic> data;

  OrganizationSettingsModel(this.data);

  factory OrganizationSettingsModel.fromMap(Map<String, dynamic> map) {
    return OrganizationSettingsModel(map);
  }

  Map<String, dynamic> toMap() => data;
}

class OrganizationModel {
  final String id;
  final String name;
  final int totalSeats;
  final int usedSeats;
  final String status; // 'active', 'suspended', 'cancelled'
  final String stripeUserId;
  final OrganizationSettingsModel settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.totalSeats,
    required this.usedSeats,
    required this.status,
    required this.stripeUserId,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrganizationModel(
      id: doc.id,
      name: data['name'] ?? '',
      totalSeats: data['totalSeats'] ?? 0,
      usedSeats: data['usedSeats'] ?? 0,
      status: data['status'] ?? 'active',
      stripeUserId: data['stripeUserId'] ?? '',
      settings: OrganizationSettingsModel.fromMap(data['settings'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'totalSeats': totalSeats,
      'usedSeats': usedSeats,
      'status': status,
      'stripeUserId': stripeUserId,
      'settings': settings.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class CreateOrganizationDataModel {
  final String name;
  final int totalSeats;
  final String stripeUserId;
  final OrganizationSettingsModel? settings;

  CreateOrganizationDataModel({
    required this.name,
    required this.totalSeats,
    required this.stripeUserId,
    this.settings,
  });
}

class UpdateOrganizationDataModel {
  final String? name;
  final int? totalSeats;
  final String? status;
  final String? stripeUserId;
  final OrganizationSettingsModel? settings;

  UpdateOrganizationDataModel({
    this.name,
    this.totalSeats,
    this.status,
    this.stripeUserId,
    this.settings,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (totalSeats != null) map['totalSeats'] = totalSeats;
    if (status != null) map['status'] = status;
    if (stripeUserId != null) map['stripeUserId'] = stripeUserId;
    if (settings != null) map['settings'] = settings!.toMap();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }
}