import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planles_custom/l10n/app_localizations.dart';

/// Checks the generated localizations themselves: both languages must exist
/// and placeholders must be substituted with locale specific wording.
///
/// Kept separate from `app_test.dart` so it compiles independently of the
/// feature screens.
void main() {
  test('Dutch and English bundles are generated', () async {
    final nl = await AppLocalizations.delegate.load(const Locale('nl'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(nl.errGeneric, 'Er is iets misgegaan. Probeer het opnieuw.');
    expect(en.errGeneric, 'Something went wrong. Please try again.');

    expect(nl.statusCancelled, 'Geannuleerd');
    expect(en.statusCancelled, 'Cancelled');

    expect(nl.retry, 'Opnieuw proberen');
    expect(en.retry, 'Try again');

    expect(nl.noName, 'Geen naam');
    expect(en.noName, 'No name');
  });

  test('placeholders are localized', () async {
    final nl = await AppLocalizations.delegate.load(const Locale('nl'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(nl.minutesShort(45), '45 min');
    expect(en.minutesShort(45), '45 min');

    expect(nl.hoursShort(2), '2 uur');
    expect(en.hoursShort(2), '2 hr');

    expect(nl.hoursMinutesShort(1, 30), '1 uur 30 min');
    expect(en.hoursMinutesShort(1, 30), '1 hr 30 min');
  });

  test('the delegate only claims supported locales', () async {
    expect(AppLocalizations.delegate.isSupported(const Locale('nl')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('de')), isFalse);
  });
}
