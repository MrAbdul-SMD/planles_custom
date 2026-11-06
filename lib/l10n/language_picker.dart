import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale_provider.dart';
import '../l10n/l10n.dart';

/// Compact language picker for app bars and login screens.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final override = ref.watch(localeOverrideProvider).value;
    final code = (override ?? Localizations.localeOf(context)).languageCode;
    return PopupMenuButton<Locale?>(
      tooltip: l10n.languageLabel,
      onSelected: (value) =>
          ref.read(localeOverrideProvider.notifier).setLocale(value),
      itemBuilder: (context) => [
        PopupMenuItem<Locale?>(
          value: null,
          child: Text(l10n.languageSystem),
        ),
        PopupMenuItem<Locale?>(
          value: const Locale('nl'),
          child: Text(l10n.languageDutch),
        ),
        PopupMenuItem<Locale?>(
          value: const Locale('en'),
          child: Text(l10n.languageEnglish),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          code.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

/// Language picker row for settings screens.
class LanguageListTile extends ConsumerWidget {
  const LanguageListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final override = ref.watch(localeOverrideProvider).value;
    final subtitle = override == null
        ? l10n.languageSystem
        : (override.languageCode == 'nl'
            ? l10n.languageDutch
            : l10n.languageEnglish);
    return ListTile(
      leading: const Icon(Icons.language_rounded),
      title: Text(l10n.languageLabel),
      subtitle: Text(subtitle),
      trailing: DropdownButton<Locale?>(
        value: override,
        onChanged: (value) =>
            ref.read(localeOverrideProvider.notifier).setLocale(value),
        items: [
          DropdownMenuItem<Locale?>(
            value: null,
            child: Text(l10n.languageSystem),
          ),
          DropdownMenuItem<Locale?>(
            value: const Locale('nl'),
            child: Text(l10n.languageDutch),
          ),
          DropdownMenuItem<Locale?>(
            value: const Locale('en'),
            child: Text(l10n.languageEnglish),
          ),
        ],
      ),
    );
  }
}
