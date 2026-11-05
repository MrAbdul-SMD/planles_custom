import '../../../core/utils/formatters.dart';

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

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
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
    required this.type,
    this.inAppEnabled = true,
    this.pushEnabled = true,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      NotificationPreference(
        type: json['type']?.toString() ?? '',
        inAppEnabled: json['inAppEnabled'] as bool? ?? true,
        pushEnabled: json['pushEnabled'] as bool? ?? true,
      );

  final String type;
  bool inAppEnabled;
  bool pushEnabled;

  Map<String, dynamic> toJson() => {
        'type': type,
        'inAppEnabled': inAppEnabled,
        'pushEnabled': pushEnabled,
      };

  String get label => switch (type) {
        'LESSON_BOOKED' => 'Les geboekt',
        'LESSON_REMINDER_24H' => 'Herinnering les (24 uur)',
        'LESSON_REMINDER_1H' => 'Herinnering les (1 uur)',
        'LESSON_CANCELLED' => 'Les geannuleerd',
        'LESSON_CHANGED' => 'Les gewijzigd',
        'LESSON_COMPLETED' => 'Les afgerond',
        'PAYMENT_SUCCESSFUL' => 'Betaling geslaagd',
        'PAYMENT_FAILED' => 'Betaling mislukt',
        'PAYMENT_REFUNDED' => 'Betaling terugbetaald',
        'PAYMENT_REQUESTED' => 'Betalingsverzoek',
        'LOW_LESSON_CREDIT' => 'Weinig lesuren over',
        'EXAM_BOOKED' => 'Examen geboekt',
        'EXAM_REMINDER_7D' => 'Herinnering examen (7 dagen)',
        'EXAM_REMINDER_24H' => 'Herinnering examen (24 uur)',
        'EXAM_CHANGED' => 'Examen gewijzigd',
        'EXAM_CANCELLED' => 'Examen geannuleerd',
        'LESSON_CARD_UPDATED' => 'Leskaart bijgewerkt',
        'INSTRUCTOR_FEEDBACK' => 'Instructeur feedback',
        'ACCOUNT_SECURITY' => 'Accountbeveiliging',
        _ => type,
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

  QuietHours copyWith({bool? enabled, String? start, String? end}) => QuietHours(
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
                .map((e) =>
                    NotificationPreference.fromJson(Map<String, dynamic>.from(e)))
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
