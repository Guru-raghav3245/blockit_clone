# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Flutter app (Dart SDK `^3.10.0-290.4.beta`). Real functionality is Android-only; the other platform folders are Flutter scaffolding.

- `flutter pub get` — install deps
- `flutter run` — run on a connected Android device/emulator
- `flutter analyze` — lint (`flutter_lints`, see `analysis_options.yaml`)
- `flutter test` — all tests (only `test/widget_test.dart` exists)
- `flutter test test/widget_test.dart --plain-name "<name>"` — single test

## Architecture

Blockit-style focus app: the user starts a timed "freedom session" that locks the phone, plus an optional Instagram Reels blocker. State is in `provider` (`SessionProvider`, `StatsProvider` in `lib/providers/`), wired in `lib/app.dart`. Features live under `lib/features/<name>/`.

**Flutter ↔ Android bridge** is the core of the app and spans several files:
- `lib/core/utils/platform_channel_helper.dart` is the only Dart wrapper for native calls: MethodChannel `com.blockit/device_admin` plus EventChannels `com.blockit/battery_stream` and `com.blockit/notifications`. Methods are handled in the `when` block in `android/.../MainActivity.kt`; add new native calls in both places.
- Sessions are enforced with Device Admin **Lock Task mode** (`DeviceAdminReceiver.kt`), not Accessibility.
- `BlockitAccessibilityService.kt` is used **only** for Instagram Reels blocking (early-returns for any package other than `com.instagram.android`). See `docs/instagram-reels-blocking.md` before touching it.
- `BlockitNotificationListenerService.kt` feeds the notifications EventChannel.

**Home-screen widget**: `TimerWidgetProvider.kt` is updated natively (for responsiveness) and reads Flutter's `FlutterSharedPreferences` directly. Dart side is `lib/core/utils/widget_helper.dart` (`home_widget` package). Widget taps arrive as `blockit://start?duration=N` URIs, handled in `WidgetLaunchObserver` (`lib/app.dart`), which sets `SessionProvider.pendingWidgetDuration` for the UI to consume. The Dart package name used in `qualifiedAndroidName` is `com.example.blockit_clone`.

**Session timing**: `SessionProvider` tracks absolute start/end `DateTime`s (not just a ticking counter) so background clock throttling doesn't skew the timer.

**Persistence**: `LocalStorageService` (SharedPreferences; keys in `core/constants/app_constants.dart`) is the source of truth for sessions, totals, and Reels-free-time records. `CloudSyncService` pushes/pulls the same data to Firestore `users/{uid}` after Google sign-in (`AuthService`, Firebase Auth). Because Kotlin reads the same SharedPreferences file, changing a stored key's name/format affects the widget and accessibility service too.
