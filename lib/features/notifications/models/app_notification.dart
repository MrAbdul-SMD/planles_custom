import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    this.userId,
    this.type,
    this.title,
    this.body,
    this.data,
    this.readAt,
    this.createdAt,
    this.dedupeKey,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: int.tryParse(json['id'].toString()) ?? 0,
        userId: int.tryParse(json['userId'].toString()),
        type: json['type']?.toString(),
        title: json['title']?.toString(),
        body: json['body']?.toString(),
        data: json['data'] is Map ? json['data'] as Map<String, dynamic> : null,
        readAt: F.date(json['readAt']?.toString()),
        createdAt: F.date(json['createdAt']?.toString()),
        dedupeKey: json['dedupeKey']?.toString(),
      );

  final int id;
  final int? userId;
  final String? type;
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime? createdAt;
  final String? dedupeKey;

  bool get isRead => readAt != null;
}

class NotificationPreference {
  NotificationPreference({
    required this.category,
    this.inAppEnabled = true,
    this.pushEnabled = true,
    this.locked = false,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      NotificationPreference(
        category: json['category']?.toString() ?? json['type']?.toString() ?? '',
        inAppEnabled: json['inAppEnabled'] as bool? ??
            (json['pushEnabled'] as bool? ?? true),
        pushEnabled: json['pushEnabled'] as bool? ?? true,
        locked: json['locked'] as bool? ?? false,
      );

  final String category;
  bool inAppEnabled;
  bool pushEnabled;
  final bool locked;

  String get type => category;

  Map<String, dynamic> toJson() => {
        'category': category,
        'pushEnabled': pushEnabled,
      };

  String label(AppLocalizations l10n) => switch (category) {
        'LESSONS' => l10n.notifPrefLessons,
        'PAYMENTS' => l10n.notifPrefPayments,
        'EXAMS' => l10n.notifPrefExams,
        'LESSON_CARDS' => l10n.notifPrefLessonCards,
        'ACCOUNT' => l10n.notifPrefAccount,
        _ => category,
      };
}

class QuietHours {
  const QuietHours({
    this.enabled = true,
    this.start = '22:00',
    this.end = '07:00',
    this.timeZone = 'Europe/Amsterdam',
  });

  factory QuietHours.fromJson(Map<String, dynamic> json) => QuietHours(
        enabled: json['enabled'] as bool? ?? true,
        start: json['start']?.toString() ?? '22:00',
        end: json['end']?.toString() ?? '07:00',
        timeZone: json['timeZone']?.toString() ?? 'Europe/Amsterdam',
      );

  final bool enabled;
  final String start;
  final String end;
  final String timeZone;

  QuietHours copyWith({bool? enabled, String? start, String? end}) =>
      QuietHours(
        enabled: enabled ?? this.enabled,
        start: start ?? this.start,
        end: end ?? this.end,
        timeZone: timeZone,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'start': start,
        'end': end,
        if (timeZone.isNotEmpty) 'timeZone': timeZone,
      };
}

class NotificationSettings {
  const NotificationSettings({
    this.quietHours = const QuietHours(),
    this.preferences = const [],
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        quietHours: json['quietHours'] is Map
            ? QuietHours.fromJson(json['quietHours'] as Map<String, dynamic>)
            : const QuietHours(),
        preferences: json['preferences'] is List
            ? (json['preferences'] as List)
                .whereType<Map>()
                .map(
                  (e) => NotificationPreference.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
            : const [],
      );

  final QuietHours quietHours;
  final List<NotificationPreference> preferences;

  Map<String, dynamic> toJson() => {
        'quietHours': quietHours.toJson(),
        'preferences': preferences.map((e) => e.toJson()).toList(),
      };
}
