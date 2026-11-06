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

  String label(AppLocalizations l10n) => switch (type) {
    'LESSON_BOOKED' => l10n.notifPrefLessonBooked,
    'LESSON_REMINDER_24H' => l10n.notifPrefLessonReminder24h,
    'LESSON_REMINDER_1H' => l10n.notifPrefLessonReminder1h,
    'LESSON_CANCELLED' => l10n.notifPrefLessonCancelled,
    'LESSON_CHANGED' => l10n.notifPrefLessonChanged,
    'LESSON_COMPLETED' => l10n.notifPrefLessonCompleted,
    'PAYMENT_SUCCESSFUL' => l10n.notifPrefPaymentSuccessful,
    'PAYMENT_FAILED' => l10n.notifPrefPaymentFailed,
    'PAYMENT_REFUNDED' => l10n.notifPrefPaymentRefunded,
    'PAYMENT_REQUESTED' => l10n.notifPrefPaymentRequested,
    'LOW_LESSON_CREDIT' => l10n.notifPrefLowLessonCredit,
    'EXAM_BOOKED' => l10n.notifPrefExamBooked,
    'EXAM_REMINDER_7D' => l10n.notifPrefExamReminder7d,
    'EXAM_REMINDER_24H' => l10n.notifPrefExamReminder24h,
    'EXAM_CHANGED' => l10n.notifPrefExamChanged,
    'EXAM_CANCELLED' => l10n.notifPrefExamCancelled,
    'LESSON_CARD_UPDATED' => l10n.notifPrefLessonCardUpdated,
    'INSTRUCTOR_FEEDBACK' => l10n.notifPrefInstructorFeedback,
    'ACCOUNT_SECURITY' => l10n.notifPrefAccountSecurity,
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
