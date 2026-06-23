# Sentri — Project Handoff

**Goal:** When a scammer calls, the user is automatically blocked, warned, or notified — without lifting a finger.

---

## How the core goal is delivered

```
Incoming call
      │
      ▼
SentriCallScreeningService  (runs in background, no Flutter engine needed)
      │
      ├─ 1. Is the number in blocked_numbers?  ──────────────► REJECT + "Scam call blocked" notification
      │
      ├─ 2. Is it in threat_entries (risk ≥ blockThreshold)?  ─► REJECT + notification
      │
      ├─ 3. Is it in caller_cache  (risk ≥ blockThreshold     ─► REJECT + notification
      │       AND auto-block is ON in settings)?
      │
      ├─ 4. Is risk score ≥ 40 (warn threshold)?  ────────────► ALLOW + "High-risk call" warning notification
      │
      └─ 5. Unknown / low risk  ───────────────────────────────► ALLOW silently
```

The `blockThreshold` (default 80) and `auto_block_high_risk` toggle are set by the user in **Settings → Protection**. They are stored in SQLite and read by the screening service on every call — no app restart needed.

**Samsung note:** Samsung One UI locks the call screening role to its own Phone app. On Samsung devices the service is registered but the role cannot be granted. Users see a "Limited" badge in Settings. All other features (blocklist, lookup, threat feed, notifications) work normally.

---

## What is fully built

| Area | Files | Status |
|---|---|---|
| Clean Architecture skeleton | `lib/core/` | ✅ |
| SQLite database (sqflite) | `lib/core/database/sentri_database.dart` | ✅ |
| Dependency injection (get_it, manual) | `lib/core/di/injection.config.dart` | ✅ |
| GoRouter navigation + bottom nav shell | `lib/core/router/` | ✅ |
| Onboarding (4 steps, Phone + Contacts + Notifications permissions) | `lib/features/onboarding/` | ✅ |
| Call log screen (real device call history) | `lib/features/call_log/` | ✅ |
| Blocklist screen (add / remove / view) | `lib/features/blocklist/` | ✅ |
| Number lookup (search, dedup, E.164 normalisation) | `lib/features/caller_id/presentation/pages/number_lookup_page.dart` | ✅ |
| Caller detail page (risk badge, report button) | `lib/features/caller_id/presentation/pages/caller_detail_page.dart` | ✅ |
| Threat feed (40 seeded entries, filter, auto-block) | `lib/features/threat_feed/` | ✅ |
| Settings (theme, auto-block, threshold, country, vishing toggle) | `lib/features/settings/` | ✅ |
| Settings persistence to SQLite | `lib/features/settings/presentation/bloc/settings_bloc.dart` | ✅ |
| Trusted contacts check (local, no upload) | `lib/features/caller_id/data/datasources/contacts_datasource.dart` | ✅ |
| Risk scoring (contacts → cache → backend) | `lib/features/caller_id/data/repositories/caller_id_repository_impl.dart` | ✅ |
| Android CallScreeningService (risk-based, reads settings + threat feed + cache) | `android/app/src/main/kotlin/com/sentri/app/SentriCallScreeningService.kt` | ✅ |
| In-call notifications (blocked + high-risk warning) | same file, `showBlockedNotification` / `showHighRiskNotification` | ✅ |
| Backend API (Express + Node.js) | `backend/` | ✅ |
| Backend report persistence (SQLite via better-sqlite3) | `backend/src/services/reportStore.js` | ✅ |
| iOS CXCallDirectoryExtension source files | `ios/SentriCallDirectory/` | ✅ (needs Xcode wiring — see below) |

---

## What still needs to be done

### P1 — Required before wide distribution (done for local testing ✅)

#### 1. Deploy the backend
The app defaults to `https://api.sentri.app/v1` which does not exist yet.
Without a running backend, risk lookup falls back to `riskScore=0` (unknown) for every number — the threat feed and community reports won't load.

```bash
# Option A — Railway (recommended, free tier)
cd backend
railway login
railway init
railway up
# Set env var in Railway dashboard: DATA_DIR=/app/data  (mount a volume for persistence)

# Option B — Fly.io
fly launch
fly deploy
fly volumes create sentri_data --size 1   # persistent SQLite
fly secrets set DATA_DIR=/data
```

After deploying, build the app with the real URL:
```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://your-app.railway.app/v1
```

#### 2. Sign the release APK
`build.gradle` currently uses debug signing for release builds (a Flutter default placeholder).

```bash
# Create a keystore (one-time)
keytool -genkey -v \
  -keystore sentri-release.jks \
  -alias sentri \
  -keyalg RSA -keysize 2048 -validity 10000

# Add to android/app/build.gradle → android { signingConfigs { release { ... } } }
# Then set: buildTypes { release { signingConfig signingConfigs.release } }
```

Store `sentri-release.jks` and its passwords securely — losing the keystore means you can never update the Play Store listing.

#### 3. Wire the iOS CXCallDirectoryExtension in Xcode

Source files are already created at `ios/SentriCallDirectory/`. Xcode steps:

1. Open `ios/Runner.xcworkspace` in Xcode
2. **File → New → Target → Call Directory Extension** → name it `SentriCallDirectory`
3. Set Bundle ID to `com.sentri.app.SentriCallDirectory`
4. Delete the generated stub Swift file; the real one is `ios/SentriCallDirectory/CallDirectoryHandler.swift`
5. **Runner target → Signing & Capabilities → + Capability → App Groups** → add `group.com.sentri.app`
6. Do the same for the `SentriCallDirectory` target
7. **SentriCallDirectory target → Build Settings → PRODUCT_BUNDLE_IDENTIFIER** → `com.sentri.app.SentriCallDirectory`
8. Archive & distribute

The extension reads blocked numbers from a shared `UserDefaults` suite (`group.com.sentri.app`).
Flutter writes to it via the `com.sentri.sentri/calldirectory` MethodChannel (called automatically after every block/unblock).

---

### P2 — High value, do soon

#### 4. Background threat feed sync (Android WorkManager)

Currently the threat feed only syncs when the user opens the app. Numbers added to the server-side threat list won't protect a user whose app is never opened.

**What to build:**
```kotlin
// android/app/src/main/kotlin/com/sentri/app/ThreatFeedSyncWorker.kt
class ThreatFeedSyncWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {
    override suspend fun doWork(): Result {
        // 1. GET /v1/threats/latest
        // 2. Replace threat_entries in SQLite
        // 3. Auto-block critical entries into blocked_numbers
        return Result.success()
    }
}
```

Register it in `MainActivity.kt`:
```kotlin
WorkManager.getInstance(this).enqueueUniquePeriodicWork(
    "threat_sync",
    ExistingPeriodicWorkPolicy.KEEP,
    PeriodicWorkRequestBuilder<ThreatFeedSyncWorker>(12, TimeUnit.HOURS).build()
)
```

Add to `build.gradle`:
```groovy
implementation "androidx.work:work-runtime-ktx:2.9.0"
```

The backend URL needs to be baked into `BuildConfig` so the worker can reach it without Flutter:
```groovy
// build.gradle defaultConfig
buildConfigField "String", "BACKEND_URL", "\"${System.getenv('BACKEND_URL') ?: 'https://api.sentri.app/v1'}\""
```

#### 5. Push notifications for new threats (FCM)
The `notificationsEnabled` toggle in Settings exists but does nothing yet.

**What to build:**
- Add Firebase to the project (`google-services.json` for Android, `GoogleService-Info.plist` for iOS)
- Backend: `POST /v1/notify` endpoint that sends FCM messages when a new high-risk number is added
- Flutter: `firebase_messaging` package, request FCM token on first launch, send token to backend

---

### P3 — Lower priority

#### 6. On-device vishing AI (TFLite)
`UserSettings.vishingDetectionEnabled` toggle exists. No model or microphone pipeline is built.

#### 7. User auth / account
`AppConstants.keyAuthToken` is defined but no login flow exists. Needed for per-user threat reports and sync.

---

## How to build & install

### Quick start — local backend via Node

```bash
# Terminal 1 — start backend
cd backend && npm install && npm run dev   # runs on port 3000

# Terminal 2 — find your WiFi IP (Windows: ipconfig | grep "IPv4")
# then build + run
flutter run --dart-define=BACKEND_URL=http://<your-wifi-ip>:3000/v1
```

### Quick start — local backend via Docker

```bash
# Start backend in Docker (data persists in Docker volume)
docker compose up -d

# Build APK against it
flutter build apk --release \
  --dart-define=BACKEND_URL=http://<your-wifi-ip>:3000/v1
```

### Release APK (already built ✅)

```
build/app/outputs/flutter-apk/app-release.apk   (24.2 MB)
Keystore: android/keystore/sentri-release.jks
Password: stored in android/key.properties  ← BACK THIS UP
```

To install on a connected Android device:
```bash
# Enable USB debugging on phone, then:
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Or transfer the APK file to the phone via USB/Drive and tap to install
```

To rebuild pointing at a deployed backend:
```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://your-deployed-backend/v1
```

### Release AAB (for Play Store)

```bash
flutter build appbundle --release \
  --dart-define=BACKEND_URL=https://your-deployed-backend/v1
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Deploy backend to Railway (no CLI needed)

1. Push repo to GitHub
2. Go to railway.app → New Project → Deploy from GitHub
3. Select the `backend/` service root
4. Add env var: `DATA_DIR=/data`
5. Add a Volume mounted at `/data` (Railway dashboard → Volume)
6. Copy the deployed URL (e.g. `https://sentri-api.up.railway.app`)
7. Rebuild APK with: `--dart-define=BACKEND_URL=https://sentri-api.up.railway.app/v1`

### Deploy backend to Fly.io

```bash
cd backend
fly launch          # uses fly.toml already configured
fly volumes create sentri_data --size 1 --region syd
fly secrets set DATA_DIR=/data
fly deploy
```

---

## Risk score reference

| Score | Label | Colour | Screening action |
|---|---|---|---|
| 0–19 | Safe | green | Allow |
| 20–39 | Low | lime | Allow |
| 40–59 | Medium | amber | Allow + warning notification |
| 60–79 | High | orange | Allow + warning notification |
| 80+ | Critical | red | Auto-block (if threshold not changed) + blocked notification |

User can lower the block threshold in **Settings → Protection → Block threshold** (slider, default 80).

---

## Architecture quick-reference

```
Presentation  (Flutter Widgets + BLoC)
      ↓
Domain        (Use Cases · Entities · Repository interfaces)
      ↓
Data          (Repository impls · DataSources · DTOs)
      ↓
Infrastructure (sqflite · Dio HTTP · CallScreeningService · Kotlin platform channels)
```

**DI:** `get_it` with manually maintained `lib/core/di/injection.config.dart`.
Do NOT run `build_runner` — it was never configured and will break the project.
Add every new injectable class by hand following the template in `injection.config.dart`.

**Database schema version: 2** — bump `_dbVersion` in `sentri_database.dart` for any new tables.

**Phone numbers:** always E.164 (`+14155552671`) inside domain/data layers.
Use `PhoneNumberUtils.toE164(raw, homeCountryCode)` at every boundary.
Never display `CallerInfo.phoneNumber` in the UI — use the raw number from the call log.

---

## File map — where to find things

```
lib/
├── main.dart                          Entry point
├── app.dart                           Root widget, BLoC providers
├── core/
│   ├── constants/app_constants.dart   AppConstants (baseUrl, keys), AppRoutes
│   ├── database/sentri_database.dart  All SQLite tables + CRUD methods
│   ├── di/injection.config.dart       Manual DI registrations ← edit this when adding features
│   ├── error/failures.dart            Sealed Failure hierarchy
│   ├── network/dio_client.dart        Dio singleton + auth interceptor
│   ├── platform/call_directory_sync.dart  iOS call directory MethodChannel wrapper
│   ├── router/app_router.dart         GoRouter config
│   └── theme/app_theme.dart           SentriColors + light/dark themes
│
└── features/
    ├── caller_id/                     Number lookup, risk score, report
    │   └── data/datasources/
    │       ├── contacts_datasource.dart    Trusted contact check (local only)
    │       ├── caller_id_remote_datasource.dart  GET /v1/caller/lookup
    │       └── caller_id_local_datasource.dart   caller_cache table
    ├── blocklist/                     User-managed block list
    ├── call_log/                      Annotated call history
    ├── threat_feed/                   Cloud threat intelligence
    ├── settings/                      Preferences + auto-block controls
    └── onboarding/                    First-run permission flow

android/app/src/main/kotlin/
├── com/sentri/sentri/MainActivity.kt      Platform channels: settings, device info
└── com/sentri/app/SentriCallScreeningService.kt  ← Core screening logic

ios/
├── Runner/AppDelegate.swift               iOS MethodChannel: syncBlocklist
└── SentriCallDirectory/
    ├── CallDirectoryHandler.swift         CXCallDirectoryExtension handler
    └── Info.plist

backend/
├── src/index.js                       Express app
├── src/routes/caller.js               GET /lookup  POST /report
├── src/routes/threats.js              GET /v1/threats/latest
└── src/services/
    ├── db.js                          SQLite connection (better-sqlite3)
    ├── reportStore.js                 Persistent community reports
    ├── threatStore.js                 40 seeded threat entries
    └── scorer.js                      Risk scoring formula
```

---

## Environment variables

| Variable | Where set | Purpose |
|---|---|---|
| `BACKEND_URL` | `--dart-define` at build time | Flutter → backend base URL |
| `DATA_DIR` | backend `.env` | Directory for `reports.db` SQLite file |
| `PORT` | backend `.env` | HTTP port (default 3000) |

---

## Key decisions made (and why)

| Decision | Reason |
|---|---|
| sqflite not Drift | Dart 3.5.3 / Drift code-gen incompatibility at project start |
| Manual DI config | build_runner never configured; adding it now would require significant migration |
| Last-9-digits matching | Handles local vs international format of same number (e.g. `0771234567` vs `+94771234567`) |
| Contacts never uploaded | Privacy USP — `ContactsDataSource` is purely local, never sent to backend |
| Samsung shows "Limited" badge | One UI locks `ROLE_CALL_SCREENING` to Samsung's own Phone app; third-party apps cannot be default screener |
| `better-sqlite3` for backend | Synchronous API simplifies Express route handlers; survives process restarts unlike in-memory Map |
