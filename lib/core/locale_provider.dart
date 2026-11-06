import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's manually chosen locale override. `null` means "follow the
/// system language" (the default).
const _kLocaleKey = 'planles.locale';

final localeOverrideProvider =
    AsyncNotifierProvider<LocaleOverrideNotifier, Locale?>(
  LocaleOverrideNotifier.new,
);

class LocaleOverrideNotifier extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_kLocaleKey);
    } else {
      await prefs.setString(_kLocaleKey, locale.languageCode);
    }
    state = AsyncData(locale);
  }
}
