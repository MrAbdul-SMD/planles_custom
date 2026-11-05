import '../../../core/network/api_client.dart';
import '../models/planning.dart';

/// Endpoints under `/api/planning`.
class PlanningRepository {
  PlanningRepository(this._api);

  final ApiClient _api;

  /// Paged list. The API filters by the caller's role, so students and
  /// instructors both use the same call.
  Future<({int total, List<Planning> items})> getAll({
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    final data = await _api.get(
      '/planning',
      query: {'pageIndex': pageIndex, 'pageSize': pageSize},
    );
    if (data is! Map) return (total: 0, items: const <Planning>[]);
    final raw = data['result'];
    return (
      total: int.tryParse(data['total'].toString()) ?? 0,
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Planning.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <Planning>[],
    );
  }

  Future<Planning> getById(int id) async {
    final data = await _api.get('/planning/$id');
    if (data is! Map) throw 'Les niet gevonden.';
    return Planning.fromJson(Map<String, dynamic>.from(data));
  }

  /// [orderItemId] is an *order item* id, not a planning id.
  Future<void> create({
    required int orderItemId,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      _api.post(
        '/planning/$orderItemId',
        body: {
          'startDate': startDate.toUtc().toIso8601String(),
          'endDate': endDate.toUtc().toIso8601String(),
        },
      );

  Future<void> confirm(int id) => _api.post('/planning/$id/confirm');

  Future<void> cancel(int id, {String? reason}) {
    final body = <String, dynamic>{
      if (reason != null && reason.isNotEmpty) 'cancelReason': reason,
    };
    return _api.post('/planning/$id/cancel', body: body.isEmpty ? null : body);
  }

  Future<void> reschedule({
    required int id,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      _api.post(
        '/planning/$id/reschedule',
        body: {
          'startDate': startDate.toUtc().toIso8601String(),
          'endDate': endDate.toUtc().toIso8601String(),
        },
      );

  Future<void> complete(int id) => _api.post('/planning/$id/complete');

  Future<void> updateNotes(int id, String notes) =>
      _api.post('/planning/$id/notes', body: {'notes': notes});

  Future<void> studentConfirmation(int id, {required bool confirmed}) =>
      _api.post(
        '/planning/$id/student-confirmation',
        body: {'confirmed': confirmed},
      );

  // ------------------------------------------------------------ lesson cards

  Future<List<LessonCardQuestion>> lessonCards(int planningId) async {
    final data = await _api.get('/lesson-cards/$planningId');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => LessonCardQuestion.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> answerLessonCards(
    int planningId,
    List<Map<String, dynamic>> answers,
  ) =>
      _api.post('/lesson-cards/$planningId', body: answers);
}
