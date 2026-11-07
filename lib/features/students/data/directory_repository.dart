import '../../../core/network/api_client.dart';
import '../../auth/models/user.dart';

/// Endpoints under `/api/student` and `/api/instructor`.
class DirectoryRepository {
  DirectoryRepository(this._api);

  final ApiClient _api;

  /// Students of the signed-in instructor (`/student/instructor`).
  Future<List<User>> myStudents() async {
    final data = await _api.get('/student/instructor');
    return _asUsers(data);
  }

  List<User> _asUsers(dynamic data) {
    final list = data is Map ? data['result'] ?? data['data'] : data;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
