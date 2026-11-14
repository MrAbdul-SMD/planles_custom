# Planles

Flutter client for the Planles driving-school platform. Talks to the existing
backend (`https://api.planles.nl/api`) and supports both **student** and
**instructor** accounts in one app (role-gated UI, shared navigation).

## Requirements

- Flutter stable (Dart SDK >= 3.9.0, as specified in `pubspec.yaml`)
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
| `json_serializable` / `json_annotation` / `build_runner` / `freezed` | Ready for model code generation when desired (see notes) |
| `formz` | Simple, composable form input validation (e.g. login) |
| `connectivity_plus` | Online/offline awareness surfaced in the UI |
| `flutter_animate` + `lottie` | Lightweight motion and expressive animations |
| `skeletonizer` + `shimmer` | Polished loading placeholders for async screens |
| `flutter_native_splash` | Branded native splash screen configuration |
| `app_links` | Deep links / payment redirect handling |
| `url_launcher` | Phone/mail/web links |
| `intl` | Dutch date/number formatting (`nl` locale) |
| `flutter_localizations` | Dutch Material strings + date symbols |
| `cached_network_image` | Cache profile/lesson images |
| `printing` | Render order invoices as PDF (`Printing.layoutPdf`) |

### Code generation

`build_runner`, `json_serializable`, and `freezed` are configured for generated
models when you want to adopt them. `build.yaml` enables `explicit_to_json` and
omits nulls. Current feature models remain hand-written/tolerant to match the
API's inconsistent payloads; migrate individual models to codegen when stable:

```bash
dart run build_runner build --delete-conflicting-outputs
```

To generate native splash assets from the `flutter_native_splash` config:

```bash
dart run flutter_native_splash:create
```

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

- **Repositories** own HTTP and JSON mapping; they never touch Flutter.
- **Models** are plain data classes with tolerant `fromJson`/`toJson` for API quirks (codegen-ready).
- **Forms** use Formz inputs for simple, testable validation where appropriate.
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

## Push notifications (Firebase Cloud Messaging)

The app registers its FCM token with the backend (`POST /auth/fcm/register`)
on sign-in and unregisters on sign-out (`POST /auth/fcm/unregister`).

Setup:
1. Create a Firebase project and add an Android app (package
   `com.example.planles_custom`) and/or an iOS app.
2. Download `google-services.json` (Android) and/or `GoogleService-Info.plist`
   (iOS) and place them in `android/app/` and `ios/Runner/` respectively.
3. `firebase_core` and `firebase_messaging` are already in `pubspec.yaml`.
4. `lib/main.dart` calls `FcmService.initialize()` (best-effort; the app
   still works without the config files, just without push).

Token registration / unregistration is wired into `AuthController`
(`login`, `register`, `restore`, `signOut`).

### Android release signing (avoid "trust/install" issues)

Release builds must be signed with a **stable** keystore/certificate; otherwise
Android may treat each APK as a different app and require re-trusting/reinstalling.

1. Create a keystore once (keep it safe, do not commit it):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (gitignored) from `android/key.properties.example`:
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```
3. Build a signed release:
   ```bash
   flutter build apk --release
   # or: flutter build appbundle --release
   ```

`android/app/build.gradle.kts` uses `android/key.properties` for release signing
when present (and falls back to debug only if missing, for local dev). Keep the
same keystore for all future releases/updates of the same app.

### macOS DMG installer

Build a release `.app` and package it as a DMG (uses built-in `hdiutil`, no extra tools required):

```bash
# Build release and create DMG
./tool/build_macos_dmg.sh

# Package an existing Release build only
./tool/build_macos_dmg.sh --no-build
```

Output: `dist/Planles-<version>-macos.dmg` (contains the app and an Applications shortcut). Version is read from `pubspec.yaml`.

## CI/CD (GitHub Actions)

Workflow: `.github/workflows/build-and-deploy.yml`

- **Triggers:** pushes to `main`, version tags (`v*`), and manual `workflow_dispatch`.
- **Web:** builds `flutter build web --release --base-href "/<repo>/" --pwa-strategy offline-first`, uploads `web-build` artifact, and deploys to **GitHub Pages** (enable Pages in repo settings: *Settings → Pages → Source: GitHub Actions*).
- **Android:** builds optimized release APKs (`--obfuscate --split-debug-info`, split-per-ABI + universal) and uploads `android-apks` artifacts (plus debug symbols). Release signing uses `android/key.properties` if provided; otherwise the Gradle config falls back to debug signing for CI artifacts.
- **macOS:** builds release `.app`, packages a DMG via `tool/build_macos_dmg.sh`, and uploads `macos-build` artifacts (`.dmg` + zipped `.app`).
- **Windows:** builds release and uploads `windows-build` artifact (zipped `x64` runner output).

> Note: `.env` is gitignored but required as a Flutter asset; CI copies `.env.example` to `.env` when missing. For production values, provide a secure `.env` via repository secrets/variables and a workflow step if needed.

### macOS pub get rsync error

If `flutter pub get` fails with `rsync: mkdir .../build/macos/SourcePackages/... failed`,
create the directories manually:

```bash
mkdir -p build/ios/SourcePackages build/macos/SourcePackages
flutter pub get
```
