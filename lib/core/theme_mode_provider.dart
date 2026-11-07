import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's manually chosen theme mode. `null` means "follow the system".
const _kThemeModeKey = 'planles.themeMode';

final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kThemeModeKey);
    return _fromRaw(raw);
  }

  Future<void> setMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _toRaw(mode));
    state = AsyncData(mode);
  }

  static ThemeMode _fromRaw(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _toRaw(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    _ => 'system',
  };
}
