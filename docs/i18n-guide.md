# i18n guide (Dutch + English via flutter gen-l10n)

The app is fully localized with Flutter's official tooling:

| File | Purpose |
| --- | --- |
| `l10n.yaml` | gen-l10n config (template `app_nl.arb`, output `lib/l10n/app_localizations.dart`) |
| `lib/l10n/app_nl.arb` | Dutch template — the source of truth |
| `lib/l10n/app_en.arb` | English translations |
| `lib/l10n/l10n.dart` | `context.l10n` extension + `describeError()` |
| `l10n_fragments/*.json` | translation fragments written by parallel migration agents |
| `tool/sync_l10n.py` | merges fragments into the ARB files and runs `flutter gen-l10n` (file-locked, safe to run concurrently) |

`generate: true` in `pubspec.yaml` makes `flutter pub get`, `flutter test` and
builds regenerate the localizations automatically.

## Using it in a widget

```dart
import '../../../l10n/l10n.dart';   // depth varies: adjust the ../ prefix

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;               // AppLocalizations, never null
    return Text(l10n.planningTitle);
  }
}
```

Rules:

* Never keep `const` on a widget whose text comes from `l10n` (it is not
  const-constructible). Drop the `const` and let the analyzer tell you where.
* `AppLocalizations.of(context)` is non-null (`nullable-getter: false`), but
  prefer the `context.l10n` extension.
* Dutch (`nl`) is the template; every key must also exist in `app_en.arb`.
  Write English that a native speaker would ship, not word-for-word Dutch.

## Key naming

* lowerCamelCase, prefix every feature key so parallel agents cannot collide:
  `login*`, `register*`, `forgot*`, `dashboard*`, `planning*`, `reschedule*`,
  `lessonCard*`, `orders*`, `orderDetail*`, `buyLessons*`, `scheduleLesson*`,
  `topUp*`, `notifications*`, `notifSettings*`, `profile*`, `editProfile*`,
  `changePassword*`, `students*`.
* Shared keys already exist — **use them, do not redefine them**:
  `retry`, `cancel`, `confirm`, `save`, `close`, `back`, `next`, `delete`,
  `edit`, `genericSuccess`, `noName`, `today`, `tomorrow`, `yesterday`,
  `minutesShort(count)`, `hoursShort(count)`, `hoursMinutesShort(hours, minutes)`,
  `navHome`, `navPlanning`, `navOrders`, `navNotifications`, `navProfile`,
  `statusConfirmed`, `statusCompleted`, `statusCancelled`, `statusPending`,
  `err*` (all transport/API error messages).

## Strings that come from shared code

| Before | Now |
| --- | --- |
| `F.money(x)`, `F.time(x)`, `F.dateTime(x)`, `F.dateShort(x)`, `F.dateMedium(x)` | unchanged — they follow the active locale automatically |
| `F.relativeDay(x)` | `F.relativeDay(l10n, x)` |
| `F.dayLabel(x)` | `F.dayLabel(l10n, x)` |
| `F.minutesLabel(x)` | `F.minutesLabel(l10n, x)` |
| `F.durationLabel(x)` | `F.durationLabel(l10n, x)` |
| `user.fullName` | `user.displayName(l10n)` |
| `planning.statusLabel` | `planning.statusLabel(l10n)` |
| `showAppSnack(context, '$e', error: true)` / `e.validationMessage` | `showAppSnack(context, describeError(context, e), error: true)` |
| `ErrorView(message: e.toString(), …)` | `ErrorView(message: describeError(context, e), …)` |
| `catch (e) { … showAppSnack(context, '$e') }` | always render errors through `describeError(context, e)` |
| `confirmAction(…, confirmLabel: 'Bevestigen')` | `confirmLabel` is now optional — pass a localized string or omit it |

`describeError(context, e)` maps client-generated `ApiException`s
(`AppErrorCode`) to translated messages and passes API-provided text through.

Server-provided text (`result.message` from the backend) is shown as-is — the
backend produces it, the app cannot translate it.

## Adding your strings

1. Write the Dutch and English text in your fragment
   `l10n_fragments/<feature>.json`:

   ```json
   {
     "planningTitle": {"nl": "Planning", "en": "Planning"},
     "lessonCount": {
       "nl": "{count} lessen",
       "en": "{count} lessons",
       "description": "Number of lessons in a package",
       "placeholders": {"count": {"type": "int"}}
     }
   }
   ```

2. Generate and check:

   ```bash
   python3 tool/sync_l10n.py     # merges fragments + flutter gen-l10n (locked)
   flutter analyze                # fix every error in the files YOU own
   dart format lib/<your files>
   ```

   `sync_l10n.py` is safe to run concurrently (advisory lock) and never
   overwrites a key that already exists in the ARB files.

3. Use the accessor: `l10n.lessonCount(3)`.

## Out of scope / deliberately untranslated

* `ApiClient`'s internal Dutch fallback messages: they are debug text paired
  with an `AppErrorCode`; the UI shows `describeError()` instead.
* Backend responses (names, validation messages) — they come from the API.
* `'–'` placeholders for null values.
