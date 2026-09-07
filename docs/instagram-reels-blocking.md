# Instagram Reels Blocking

How the Reels-blocking feature works, which Android permissions it depends on,
and why Accessibility Service can't be replaced for this one feature even
though every other feature in the app has been migrated off it.

## What the feature does

When "Block Instagram Reels" is enabled in Settings, the app:

1. Detects that Instagram (`com.instagram.android`) is in the foreground.
2. Detects that the user is specifically on the **Reels tab** (not just
   anywhere in Instagram).
3. Shows a full-screen block overlay.
4. Automatically taps Instagram's own "Home" tab to redirect the user off
   Reels, falling back to a system back-action if that tap isn't possible.
5. Tracks "clean" (Reels-free) time spent in Instagram and buffers it for the
   home-screen widget.

Implementation lives entirely in
`android/app/src/main/kotlin/com/example/blockit_clone/BlockitAccessibilityService.kt`,
scoped with an early return so it only ever acts on `com.instagram.android` —
it does nothing for any other app.

## Permission used: Accessibility Service

This is the only feature in the app that uses Accessibility. General focus
sessions (the timer/lock feature) are enforced entirely through Device Admin
Lock Task mode and don't touch Accessibility at all — see
[`../lib/providers/session_provider.dart`](../lib/providers/session_provider.dart).

Accessibility gives the service two capabilities that no other Android
permission exposes:

### 1. Reading another app's UI tree

```kotlin
root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/root_clips_layout")
root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/clips_tab")
root.findAccessibilityNodeInfosByText("Reels")
```

This is how the service tells "Reels tab is visible" apart from "Instagram is
open" (feed, DMs, profile, etc.). Without it, the app can only know that
Instagram as a whole is foreground — not which screen inside it is showing.

### 2. Synthesizing input into another app's UI

```kotlin
node.performAction(AccessibilityNodeInfo.ACTION_CLICK)   // tap Instagram's own Home tab
performGlobalAction(GLOBAL_ACTION_BACK)                   // fallback: system back
```

This is how the service redirects the user off Reels without just showing a
static block screen — it actually drives Instagram back to its Home tab, or
presses back, on the user's behalf.

## Why it can't be migrated

The two capabilities above only exist behind two Android APIs:
`AccessibilityService`, or `MediaProjection` (screen capture). There is no
permission tier below Accessibility (Usage Access, "Display over other apps",
etc.) that exposes either one.

| Capability needed | Usage Access | Display Over Apps (`SYSTEM_ALERT_WINDOW`) | Accessibility | MediaProjection |
|---|---|---|---|---|
| Know which app is foreground | ✅ | ❌ | ✅ | ❌ (would need frame analysis) |
| Know which *tab/screen* is showing inside an app | ❌ | ❌ | ✅ (read UI node tree) | ⚠️ possible via pixel/OCR matching on captured frames |
| Draw a block screen on top | ❌ | ✅ | ✅ | ❌ (capture only, no drawing) |
| Tap a button inside another app | ❌ | ❌ | ✅ (`performAction`/`performGlobalAction`) | ❌ (no equivalent — capture only) |

**Usage Access + Display Over Apps** (the combination general session
blocking now relies on, via Device Admin Lock Task, instead of Accessibility)
gets you app-level detection and a block overlay, but not tab-level detection
and not the auto-redirect tap. Enabling Reels blocking on those permissions
alone would mean blocking all of Instagram whenever the toggle is on, not
just Reels, and the user would have to dismiss the overlay and back out
manually instead of being silently redirected.

**MediaProjection** is the only theoretical non-Accessibility path to real
parity: continuously capture the screen, run pixel/template matching to
detect the Reels UI, and force-foreground the app's own block screen instead
of tapping Instagram's Home tab directly (there's no "click a coordinate in
another app" API outside Accessibility, so the auto-redirect-to-Home trick
specifically has no substitute either way). This was evaluated and rejected:

- It replaces one sensitive-looking permission with another. Screen-capture
  consent reads as scarier to most users than Accessibility, and Play Store
  review scrutiny on persistent `MediaProjection` use is at least as heavy.
- It's continuous frame capture + image analysis running whenever Instagram
  is open — meaningfully worse for battery/CPU than parsing accessibility
  events.
- Android shows a persistent "screen being recorded" system indicator the
  whole time it's active, which is arguably a worse user experience than the
  existing Accessibility toggle.
- It still can't replicate the silent tap-to-Home redirect — only the
  detection half improves, not the response half.

## Current scope

Because this is the one feature that has to stay on Accessibility, the app
only asks for the permission when the user actually turns Reels blocking on
(see `lib/features/settings/settings_screen.dart`), instead of gating it
behind general session start. A user who never enables Reels blocking is
never asked for Accessibility at all.
