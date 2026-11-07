import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme_mode_provider.dart';
import '../l10n/l10n.dart';

/// Theme (light/dark/system) picker row for settings screens.
class ThemeModeListTile extends ConsumerWidget {
  const ThemeModeListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    return ListTile(
      leading: const Icon(Icons.brightness_6_rounded),
      title: Text(l10n.themeModeLabel),
      subtitle: Text(_label(l10n, mode)),
      trailing: DropdownButton<ThemeMode>(
        value: mode,
        onChanged: (value) {
          if (value != null) {
            ref.read(themeModeProvider.notifier).setMode(value);
          }
        },
        items: [
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text(l10n.themeModeSystem),
          ),
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text(l10n.themeModeLight),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text(l10n.themeModeDark),
          ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
    ThemeMode.light => l10n.themeModeLight,
    ThemeMode.dark => l10n.themeModeDark,
    _ => l10n.themeModeSystem,
  };
}
