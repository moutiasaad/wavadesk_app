# Wavadesk Agent (Flutter)

Mobile inbox for Wavadesk support agents — WhatsApp, website chat, Messenger,
Instagram, Email, Telegram and SMS in one queue, with AI-suggested replies.

Built strictly from **Wavadesk Flutter Design System v1.0**. Bundle id:
`com.wavadesk` (Android `applicationId` + iOS `PRODUCT_BUNDLE_IDENTIFIER`).

## Run

```sh
flutter pub get
flutter run
```

### Sign in

The login screen follows `01 Login Screen.md`. Without an API URL it uses
`SimulatedAuthApi`: any valid email/phone + an 8+ character password signs in.
Demo triggers:

| Input | Result |
|---|---|
| password `wrongpassword` | 401 "incorrect email or password" |
| identifier containing `disabled` / `suspended` | 403 banners |
| identifier containing `locked` | 429 with a 30s live countdown |
| identifier containing `server` | 5xx banner |
| identifier containing `2fa` / `team` | 2FA / workspace-picker routes (placeholders) |

Debug sessions last 2 minutes, so restarting after that shows the biometric
button (when enabled from the post-login sheet on a device with biometrics).

Real API: `flutter run --dart-define=WAVADESK_API_URL=https://…` — expects the
contract in the spec (`POST /api/v1/auth/login`, `POST /api/v1/auth/refresh`).
Tokens live in `flutter_secure_storage`.

The app runs on **in-memory sample data** (`lib/core/data/mock_data.dart`) —
no backend is wired yet. All actions (claim, assign, resolve + undo, snooze,
send, AI suggestion/regenerate/rewrite, delivery ticks, typing, a colleague
claiming the "هيا المطيري" chat after ~9s) are simulated in the controllers.

Demo affordance: long-press the app version on the Account tab to cycle the
connection banner (online → connecting → offline).

## Structure

```
lib/
  core/theme/      tokens: AppColors, AppTextStyles, AppSpacing, AppRadius,
                   AppShadows, AppMotion, AppIcons, AppTheme (light/dark)
  core/widgets/    shared components (AppButton, AppAvatar, StatusBadge, …)
  core/models/     domain models + enums (Channel, ConversationStatus, …)
  core/data/       Riverpod controllers + mock data
  core/router/     go_router routes (Routes.*)
  core/utils/      l10n accessors, enum labels, formatters, ltr() bidi helper
  features/        conversations, chat, customer, search, filters, dashboard,
                   notifications, knowledge, account, auth, shell
```

Tokens are read through context: `context.colors.primary`,
`context.text.h1`, `context.shadows.medium`.

## Localization

Arabic (RTL, default) and English. Strings live in per-feature fragments in
`l10n_parts/<feature>.<locale>.arb` (keys follow
`feature_element_description`). After editing them:

```sh
dart run tool/merge_l10n.dart && flutter gen-l10n
```

The merge fails on duplicate keys or a key missing from one locale.

## Fonts

Cairo 400–800 and IBM Plex Mono 400 are bundled in `assets/fonts/` (works
offline, no runtime download).

## Connecting the real backend

Replace the `MockData` reads in `lib/core/data/*_controller.dart` with calls to
the Wavadesk Laravel API; the UI depends only on the model classes and
controller methods.
