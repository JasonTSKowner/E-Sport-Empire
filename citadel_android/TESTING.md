# Crownforge V0.2 verification

The application uses Java 17, Android Gradle Plugin 8.7.3, Gradle 8.9 and Android SDK 35. Its application ID remains `com.jasontsk.projectcitadel`, so installing the debug APK over an identically signed V0.1 installation preserves app data. A differently signed installation cannot be upgraded in place.

## Automated checks

Run from `citadel_android/` with an installed Android SDK and Gradle 8.9:

```sh
gradle :app:assembleDebug :app:assembleDebugAndroidTest :app:testDebugUnitTest :app:lintDebug --continue
```

`GameSystemsTest` contains 19 independent JVM regressions covering grid conversion, occupancy/boundaries, free moves, resource transaction validation, timed construction, exhausted builders, hut completion, wall currency/connection rules, capacity limits, backward clocks, chronological offline completions, duplicate completion prevention, Town Hall 1–5 progression, independent XP, reversible placement and camera constraints.

`CrownforgeInstrumentation` is a native Android test runner. It runs 12 device scenarios: version 2 save roundtrip/settings, V0.1 migration, malformed row and placement repair, backup recovery, future-version preservation, saved production after clock rollback, startup/village launch, real Android touch events for pan/pinch/selection, shop/build/move/cancel flow, original building and Town Hall level rendering, synthesized audio generation/lifecycle, and activity restart restoring positions/settings. It uses an isolated emulator installation and intentionally resets that installation's game data.

Install and run the device harness on a disposable emulator:

```sh
adb install -r -t app/build/outputs/apk/debug/app-debug.apk
adb install -r -t app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb shell am instrument -w -r com.jasontsk.projectcitadel.test/com.jasontsk.projectcitadel.CrownforgeInstrumentation
```

A successful run ends with `CROWNFORGE_RESULT: PASS`. Failed cases emit a stack trace and `CROWNFORGE_RESULT: FAIL`. Do not interpret the successful APK compilation or instrumentation process exit alone as a runtime pass.

## CI artifacts

The Crownforge-only workflow runs on `citadel-apk-build` and `crownforge-v02` when the Android project or its workflow changes. The build job runs JUnit and Android lint and uploads `Crownforge-V0.2-debug.apk`. Separate Android API 29 and API 35 emulator jobs install both APKs and run the native harness. Their artifacts contain instrumentation results, logcat and screenshots of startup, village, selection, shop, wall placement, moved wall, building evolution and restored village. The APK is uploaded before device checks, preserving a reviewable build if a device test fails.

## Physical-device acceptance

Emulator coverage does not establish physical-device frame rate, speaker quality or subjective polish. Before a Play Store release, verify on at least one mid-range Android phone:

- Listen to the 1.75-second original startup sound, effects, ambience and background music; exercise mute/volume and background/resume behavior.
- Check pan/pinch responsiveness and touch targets with a thumb, across portrait screen sizes and cutouts.
- Review shadows, sprite overlap, wall junctions and all five Town Hall silhouettes at minimum/maximum zoom.
- Leave real upgrades running while force-closing and reopening, and verify production/deadlines against wall-clock time.
- Profile a large village with at least 100 walls; the V0.2 progression unlocks fewer walls, so use an explicit development fixture for this stress test.

This document describes the checks provided. The delivery report must distinguish checks actually executed from checks still pending; generated test files are not evidence of a passing run.
