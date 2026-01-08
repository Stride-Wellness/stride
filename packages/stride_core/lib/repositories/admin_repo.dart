import 'package:cloud_functions/cloud_functions.dart';
import 'package:stride_core/models/admin_m.dart';

class AdminRepository {
  final FirebaseFunctions _functions;

  AdminRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable(name);
    final result = await callable.call(data);
    final raw = result.data;
    if (raw is! Map) {
      throw Exception('Unexpected response from $name');
    }
    return Map<String, dynamic>.from(raw as Map);
  }

  AdminModel _parseAdmin(dynamic adminData) {
    final map = Map<String, dynamic>.from(adminData as Map);
    final id = map['id'] as String? ?? '';
    return AdminModel.fromMap(map, id);
  }

  Future<List<AdminModel>> getAll({int limitCount = 100, AdminPrivilegeLevel? privilegeLevel}) async {
    final data = await _call('get_admins', {
      'limit': limitCount,
      if (privilegeLevel != null) 'privilegeLevel': privilegeLevel.index,
    });

    if (!(data['success'] as bool? ?? false)) {
      throw Exception(data['message'] ?? 'Failed to get admins');
    }

    final admins = (data['admins'] as List<dynamic>? ?? [])
        .map((admin) => _parseAdmin(admin))
        .toList();
    return admins;
  }

  Future<AdminModel?> getById(String adminId) async {
    final data = await _call('get_admin_by_id', {'userId': adminId});

    if (!(data['success'] as bool? ?? false)) {
      return null;
    }

    return _parseAdmin(data['admin']);
  }

  Future<List<AdminModel>> getByIds(List<String> adminIds) async {
    if (adminIds.length > 10) {
      throw Exception('Cannot get more than 10 admins by ID at once');
    }

    final data = await _call('get_admins', {'userIds': adminIds});

    if (!(data['success'] as bool? ?? false)) {
      throw Exception(data['message'] ?? 'Failed to get admins by IDs');
    }

    final admins = (data['admins'] as List<dynamic>? ?? [])
        .map((admin) => _parseAdmin(admin))
        .toList();
    return admins;
  }

  Future<List<AdminModel>> search(String term) async {
    final admins = await getAll(limitCount: 1000);
    final query = term.toLowerCase();
    return admins.where((admin) => admin.name.toLowerCase().contains(query)).toList();
  }

  Future<List<AdminModel>> getByPrivilegeLevel(AdminPrivilegeLevel privilegeLevel) async {
    return getAll(limitCount: 1000, privilegeLevel: privilegeLevel);
  }

  Future<Map<AdminPrivilegeLevel, int>> getStats() async {
    final admins = await getAll(limitCount: 1000);
    final stats = <AdminPrivilegeLevel, int>{};

    for (final admin in admins) {
      stats[admin.privilege] = (stats[admin.privilege] ?? 0) + 1;
    }

    return stats;
  }

  Future<bool> hasPermission(String adminId, AdminPrivilegeLevel requiredLevel) async {
    final admin = await getById(adminId);
    if (admin == null) return false;
    return admin.privilege.index <= requiredLevel.index;
  }

  Future<String> create(CreateAdminDataModel data) async {
    final response = await _call('create_admin', {
      'email': data.email,
      'password': data.password,
      'name': data.name,
      'privilege': data.privilege.index,
    });

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to create admin');
    }

    return response['userId'] as String;
  }

  Future<void> update(UpdateAdminDataModel data) async {
    final response = await _call('update_admin', data.toMap());

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to update admin');
    }
  }

  Future<void> delete(String userId) async {
    final response = await _call('delete_admin', {'userId': userId});

    if (!(response['success'] as bool? ?? false)) {
      throw Exception(response['message'] ?? 'Failed to delete admin');
    }
  }

  List<AdminPrivilegeLevel> getAvailablePrivilegeLevels(AdminPrivilegeLevel adminLevel) {
    final levels = <AdminPrivilegeLevel>[];
    for (int i = adminLevel.index + 1; i <= AdminPrivilegeLevel.readOnly.index; i++) {
      levels.add(AdminPrivilegeLevel.values[i]);
    }
    return levels;
  }
}
