import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Central place for every user facing conversion (currency, dates, durations).
///
/// The Planles API returns a handful of values as strings that are actually
/// numbers or intervals (`"45.00"`, `"01:00:00"`), so the helpers below are
/// deliberately tolerant.
///
/// ## Locale
///
/// Pure formatting ([money], [dateShort], [time], …) resolves its locale from
/// `Intl.defaultLocale`, which the app keeps in sync with the active Flutter
/// locale (see `_IntlLocaleDelegate` in `lib/app/app.dart`).
///
/// Helpers that render *words* ("Vandaag", "45 min") take the
/// [AppLocalizations] of the current context instead, because those strings
/// come from the ARB files:
///
/// ```dart
/// final l10n = context.l10n;
/// F.relativeDay(l10n, planning.startDate);
/// ```
class F {
  F._();

  /// Effective locale tag; Dutch until the app has resolved its locale.
  static String get _locale => Intl.defaultLocale ?? 'nl';

  static String money(num? value) {
    if (value == null) return '–';
    return NumberFormat.currency(
      locale: _locale,
      symbol: '€',
      decimalDigits: 2,
    ).format(value);
  }

  /// Parses `"45.00"` / `45` / `null` into a `double`.
  static double? toDouble(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }

  /// Parses a `HH:MM:SS` interval into minutes (`"01:00:00"` → 60).
  static int? durationMinutes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  static String durationLabel(AppLocalizations l10n, String? raw) {
    final minutes = durationMinutes(raw);
    if (minutes == null) return '–';
    return minutesLabel(l10n, minutes);
  }

  /// `45 min` / `2 uur` / `1 uur 30 min`.
  static String minutesLabel(AppLocalizations l10n, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l10n.minutesShort(m);
    if (m == 0) return l10n.hoursShort(h);
    return l10n.hoursMinutesShort(h, m);
  }

  static DateTime? date(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static String dateShort(DateTime? value) =>
      value == null ? '–' : DateFormat('dd-MM-yyyy', _locale).format(value);

  static String dateMedium(DateTime? value) => value == null
      ? '–'
      : DateFormat('EEEE d MMMM yyyy', _locale).format(value);

  static String dateTime(DateTime? value) =>
      value == null ? '–' : DateFormat('dd-MM-yyyy HH:mm', _locale).format(value);

  static String time(DateTime? value) =>
      value == null ? '–' : DateFormat('HH:mm', _locale).format(value);

  /// "Vandaag" / "Morgen" / "Gisteren" / "maandag 9 november".
  static String relativeDay(AppLocalizations l10n, DateTime? value) {
    if (value == null) return '–';
    switch (_dayDiff(value)) {
      case 0:
        return l10n.today;
      case 1:
        return l10n.tomorrow;
      case -1:
        return l10n.yesterday;
    }
    return DateFormat('EEEE d MMMM', _locale).format(value);
  }

  /// Compact variant of [relativeDay] that falls back to `dd/MM` for dates
  /// further away, so it never overflows a small box.
  static String dayLabel(AppLocalizations l10n, DateTime? value) {
    if (value == null) return '–';
    switch (_dayDiff(value)) {
      case 0:
        return l10n.today;
      case 1:
        return l10n.tomorrow;
      case -1:
        return l10n.yesterday;
    }
    return DateFormat('dd/MM', _locale).format(value);
  }

  static int _dayDiff(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    return day.difference(today).inDays;
  }
}
