# Planles

Flutter client for the Planles driving-school platform. Talks to the existing
backend (`https://api.planles.nl/api`) and supports both **student** and
**instructor** accounts in one app (role-gated UI, shared navigation).

## Requirements

- Flutter 3.47+ / Dart 3.13+
- A running instance of [planles-backend](../planles-backend) (defaults to
  `https://api.planles.nl`, override with `--dart-define`)

## Run

```bash
# Live API (default)
flutter run

# Local backend
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api

# Sanity checks
flutter analyze
flutter test
flutter build apk --debug
```

## Packages

| Package | Why |
| --- | --- |
| `dio` | HTTP client with interceptors (Bearer token, 401 hook, logging) |
| `pretty_dio_logger` | Request/response logging while developing |
| `flutter_riverpod` | Dependency injection + async state (`FutureProvider`, `Notifier`) |
| `go_router` | Declarative routing with auth redirects via `refreshListenable` |
| `shared_preferences` | Persist the JWT + last-known user between launches |
| `intl` | Dutch date/number formatting (`nl` locale) |
| `flutter_localizations` | Dutch Material strings + date symbols |
| `cached_network_image` | Cache profile/lesson images |
| `printing` | Render order invoices as PDF (`Printing.layoutPdf`) |
| `url_launcher` | Phone/mail links (support, guard contact) |

**Deliberately not used:** `json_serializable` / `freezed` / `build_runner`.
The API's JSON shapes are inconsistent (`result` vs `data`, `error` vs
`message` keys, multipart `data` fields), so models use hand-written
`fromJson` factories — no code generation, full control over fallbacks.

## Architecture

Feature-first, three layers per feature, plus a thin `core/` and `app/`:

```
lib/
├── main.dart                  # ProviderContainer, 401 handler, session restore
├── app/                       # router, MaterialApp wrapper, theme, bottom-bar shell
├── core/
│   ├── network/               # ApiClient (Dio), ApiException
│   ├── providers.dart         # tokenStorageProvider, apiClientProvider
│   ├── storage/               # TokenStorage (JWT + cached user)
│   └── utils/formatters.dart  # dates, times, currency (nl)
├── shared/widgets.dart        # buttons, fields, empty/error states
└── features/<name>/
    ├── data/                  # <name>_repository.dart  → API calls only
    ├── models/                # plain fromJson models (no codegen)
    ├── providers/             # Riverpod providers (FutureProvider / Notifier)
    └── screens/               # widgets, one file per screen
```

Rules of thumb:

- **Repositories** own HTTP and JSON parsing; they never touch Flutter.
- **Providers** expose async state; screens only read (`ref.watch`) and call
  action methods (`ref.read(...Provider.notifier).doThing()`).
- **Screens** are plain widgets; navigation goes through `go_router`.
- Mutations invalidate the relevant providers so lists/detail refresh.

### Features

| Feature | Screens |
| --- | --- |
| `auth` | login, register (2-step OTP), forgot password |
| `dashboard` | role-aware home with upcoming lessons, actions |
| `planning` | list (3 tabs), detail (confirm/cancel/reschedule/complete, notes, student confirmation, lesson cards, logs), reschedule, lesson cards |
| `orders` | list, detail (pay / request payment / invoice PDF / inplannen), buy lessons, schedule lesson |
| `balance` | iDEAL/credit-card top-up |
| `notifications` | cursor-paginated list + settings (preferences, quiet hours) |
| `profile` | profile, edit profile, change password |
| `students` | instructor-only student directory |

## Routing & auth

- Static route table in `lib/app/router.dart`; five bottom-bar tabs for both
  roles (Home / Planning / Bestellingen / Meldingen / Profiel). Instructor-only
  entries (students, complete lesson, notes, request payment) are gated in the
  UI, not the router.
- `routerProvider` listens to `authControllerProvider` and pushes state into a
  `ValueNotifier<AuthState>` wired to `GoRouter.refreshListenable`, so login /
  logout / session-expiry redirect automatically.
- `AuthState` is a sealed class: `AuthUnknown` (restoring) →
  `AuthUnauthenticated` / `Authenticated`.
- On 401 the API client clears the token and lands on `/login`.

## API notes (quirks handled in code)

- Base URL `https://api.planles.nl/api`, `Authorization: Bearer <jwt>`, no
  refresh tokens — a 401 means re-login.
- Register and `PATCH /profile` send **multipart** with the JSON stringified
  into a form field named `data` (OTP / password live inside that JSON).
- `POST /planning/:id` expects an **order-item** id; `GET /order/:id/trial-status`
  expects a **student user id**.
- Pagination is `pageIndex` / `pageSize` → `{ total, result }`; notifications
  are cursor-based.
- Responses may use `error` or `message` for failures; instructors list
  answers `{ data: [...] }` while other list endpoints use `{ result: [...] }`.
- Locale falls back `nl_NL` → `nl` for date symbol loading.

## Tests

`test/app_test.dart` contains widget smoke tests: signed-out redirect to
login, empty-form validation, and navigation between auth screens.

## Configuration (flutter_dotenv)

Client-side configuration lives in a `.env` file that is bundled as a Flutter
asset:

```dotenv
# .env (gitignored — copy from .env.example)
API_BASE_URL=https://api.planles.nl/api
```

- Register the file under `flutter: assets:` in `pubspec.yaml` (already done).
- `lib/main.dart` calls `await dotenv.load()` before creating the `ApiClient`.
- `ApiClient.resolvedBaseUrl` reads `API_BASE_URL` and falls back to the
  compiled-in default (`https://api.planles.nl/api`) when the file or the key
  is missing, so the app still boots without a `.env`.
- Never store secrets in `.env`: Flutter assets are part of the binary and
  can be extracted by anyone. `.env` is gitignored; `.env.example` is the
  committed template.

## Internationalization (flutter gen-l10n)

The app ships Dutch (`nl`, template) and English (`en`), following the system
locale with Dutch as fallback.

- Configuration: `l10n.yaml` (`arb-dir: lib/l10n`, template `app_nl.arb`).
- ARB files: `lib/l10n/app_nl.arb` / `lib/l10n/app_en.arb`.
- Generated: `lib/l10n/app_localizations.dart` (via `flutter gen-l10n`,
  triggered by `generate: true` in `pubspec.yaml`).
- Access in widgets: `final l10n = context.l10n;` (extension in
  `lib/l10n/l10n.dart`), then `l10n.someKey`.
- Shared helpers: `describeError(context, e)` maps `ApiException`s to
  translated messages; `F.relativeDay(l10n, …)` / `F.minutesLabel(l10n, …)`
  etc. take the localizations for word-based labels.
- Parallel migration workflow: each feature writes its keys to
  `l10n_fragments/<feature>.json`; `python3 tool/sync_l10n.py` merges them
  into the ARB files under an advisory lock and regenerates the localizations.
  See `docs/i18n-guide.md` for the conventions.
