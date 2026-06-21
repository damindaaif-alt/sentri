# Sentri — Developer Guide

Privacy-first, AI-powered call blocking app. Flutter (iOS + Android).
GitHub: https://github.com/damindaaif-alt/sentri

---

## Architecture

```
Presentation (Flutter Widgets + BLoC)
        ↓
Domain (Use Cases · Entities · Repository Interfaces)
        ↓
Data (Repository Impls · Data Sources · DTOs)
        ↓
Infrastructure (Drift DB · Dio HTTP · Native Call APIs · TFLite)
```

**Pattern:** Clean Architecture with BLoC state management.
**DI:** `get_it` + `injectable` (code-generated via `@injectable` annotations).
**Database:** Drift (type-safe SQLite). Schema in `lib/core/database/sentri_database.dart`.
**Networking:** Dio with auth interceptor. Base URL in `AppConstants.baseUrl`.

---

## Folder structure

```
lib/
├── main.dart               # Entry point — calls configureDependencies(), runs SentriApp
├── app.dart                # Root widget — MaterialApp.router, theme, BLoC providers
├── core/
│   ├── constants/          # AppConstants, AppRoutes
│   ├── database/           # SentriDatabase (Drift) — all tables defined here
│   ├── di/                 # injection.dart + generated injection.config.dart
│   ├── error/              # Sealed Failure hierarchy
│   ├── network/            # DioClient (singleton, auth interceptor)
│   ├── router/             # GoRouter config + HomeShell bottom nav
│   ├── theme/              # AppTheme (light/dark) + SentriColors
│   └── utils/              # PhoneNumberUtils (E.164 normalisation)
└── features/
    ├── caller_id/          # Number lookup, risk score, spoofing detection
    ├── blocklist/          # User-managed block/whitelist
    ├── call_log/           # Annotated call history
    ├── threat_feed/        # Cloud threat intelligence ingestion
    ├── settings/           # User preferences, theme, AI toggles
    └── onboarding/         # First-run permission flow
```

Each feature follows: `data/` → `domain/` → `presentation/` layers.

---

## Key conventions

- **No force-unwraps (`!`)** without a guard comment explaining why it's safe.
- **Errors:** Use the `Failure` sealed class hierarchy (`lib/core/error/failures.dart`). Never swallow exceptions silently.
- **Use cases return `(T?, Failure?)`** tuples — never throw across layer boundaries.
- **BLoC events are `sealed` classes** with `final` subclasses. States are also sealed.
- **Repository interfaces use `abstract interface class`** — one method per interface method, no default implementations.
- **Phone numbers are always E.164** (`+14155552671`) inside domain/data layers. Normalise at the boundary with `PhoneNumberUtils.toE164()`.
- **No hardcoded strings** — use `AppConstants` or localisation keys.
- **Colors:** Always use `SentriColors` — never raw hex literals in widgets.

---

## Code generation

Run after modifying Drift tables, Freezed models, or injectable registrations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Platform specifics

### Android
- `SentriCallScreeningService.kt` — screens calls against local blocklist without the Flutter engine running.
- Must be set as the **default call screening app** by the user (prompted in onboarding).
- Queries `sentri.db` SQLite directly (written by Drift in the Flutter layer).

### iOS
- Uses `CXCallDirectoryExtension` for caller ID (separate app extension target — add in Xcode).
- Microphone access for vishing detection is **opt-in** only — check `UserSettings.vishingDetectionEnabled` before activating.

---

## Risk score reference

| Score | Label    | Color               | Default action   |
|-------|----------|---------------------|-----------------|
| 0–19  | Safe     | `riskSafe` green    | Allow            |
| 20–39 | Low      | `riskLow` lime      | Allow + notify  |
| 40–59 | Medium   | `riskMedium` amber  | Allow + banner  |
| 60–79 | High     | `riskHigh` orange   | Warn / block    |
| 80+   | Critical | `riskCritical` red  | Auto-block      |

---

## Running locally

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Testing

```bash
flutter test
```
