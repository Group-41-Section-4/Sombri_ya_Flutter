import 'package:flutter_sombri_ya/data/providers/api_provider.dart';

class ProfileRepository {
  final ApiProvider _api;
  ProfileRepository({ApiProvider? apiProvider}) : _api = apiProvider ?? ApiProvider();

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final data = await _api.getWithParams('/users/profile', {'user_id': userId});
    return (data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateField({
    required String userId,
    required String fieldKey,
    required String newValue,
  }) async {
    final data = await _api.getWithBody('/users/update', {
      'user_id': userId,
      'field': fieldKey,
      'value': newValue,
    });
    return (data as Map).cast<String, dynamic>();
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.getWithBody('/users/change-password', {
      'user_id': userId,
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
