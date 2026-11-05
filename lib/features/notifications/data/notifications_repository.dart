import '../../../core/network/api_client.dart';
import '../models/app_notification.dart';

/// Endpoints under `/api/notifications`.
class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  /// Cursor paginated (newest first). Pass `null` for the first page.
  Future<({List<AppNotification> items, int? nextCursor})> list({int? cursor}) async {
    final query = <String, dynamic>{
      'cursor': ?cursor,
    };
    final data = await _api.get('/notifications', query: query);
    if (data is! Map) return (items: const <AppNotification>[], nextCursor: null);
    final raw = data['notifications'];
    return (
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <AppNotification>[],
      nextCursor: int.tryParse(data['nextCursor'].toString()),
    );
  }

  Future<int> unreadCount() async {
    final data = await _api.get('/notifications/unread-count');
    return data is Map ? int.tryParse(data['count'].toString()) ?? 0 : 0;
  }

  Future<void> markRead(int id) => _api.post('/notifications/$id/read');

  Future<void> markAllRead() => _api.post('/notifications/read-all');

  Future<NotificationSettings> settings() async {
    final data = await _api.get('/notifications/settings');
    if (data is! Map) return const NotificationSettings();
    return NotificationSettings.fromJson(Map<String, dynamic>.from(data));
  }

  Future<NotificationSettings> updateSettings(NotificationSettings settings) async {
    final data = await _api.patch('/notifications/settings', body: settings.toJson());
    if (data is! Map) return settings;
    return NotificationSettings.fromJson(Map<String, dynamic>.from(data));
  }
}
