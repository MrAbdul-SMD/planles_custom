import 'package:intl/intl.dart';

/// Central place for every user facing conversion (currency, dates, durations).
///
/// The Planles API returns a handful of values as strings that are actually
/// numbers or intervals (`"45.00"`, `"01:00:00"`), so the helpers below are
/// deliberately tolerant.
class F {
  F._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'nl_NL',
    symbol: '€',
    decimalDigits: 2,
  );

  static String money(num? value) {
    if (value == null) return '–';
    return _currency.format(value);
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

  static String durationLabel(String? raw) {
    final minutes = durationMinutes(raw);
    if (minutes == null) return '–';
    return minutesLabel(minutes);
  }

  static String minutesLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h uur';
    return '$h uur $m min';
  }

  static DateTime? date(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static String dateShort(DateTime? value) {
    if (value == null) return '–';
    return DateFormat('dd-MM-yyyy').format(value);
  }

  static String dateMedium(DateTime? value) {
    if (value == null) return '–';
    return DateFormat('EEEE d MMMM yyyy', 'nl_NL').format(value);
  }

  static String dateTime(DateTime? value) {
    if (value == null) return '–';
    return DateFormat('dd-MM-yyyy HH:mm').format(value);
  }

  static String time(DateTime? value) {
    if (value == null) return '–';
    return DateFormat('HH:mm').format(value);
  }

  static String relativeDay(DateTime? value) {
    if (value == null) return '–';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Vandaag';
    if (diff == 1) return 'Morgen';
    if (diff == -1) return 'Gisteren';
    return DateFormat('EEEE d MMMM', 'nl_NL').format(value);
  }

  /// Compact variant of [relativeDay] that falls back to `dd/MM` for dates
  /// further away, so it never overflows a small box.
  static String dayLabel(DateTime? value) {
    if (value == null) return '–';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Vandaag';
    if (diff == 1) return 'Morgen';
    if (diff == -1) return 'Gisteren';
    return DateFormat('dd/MM').format(day);
  }
}
