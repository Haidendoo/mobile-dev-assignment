# Forest Sokoban — Android application

Version 0.1.0 is the A02 campaign foundation. It implements twelve bundled puzzles,
chapter unlocking, movement/pushing, Undo, confirmed Restart, pause, monotonic active
time, SQLite save/restore, personal bests, and transactional local score outbox.

Story, audio/settings, online publishing, Auth/OTP and verified challenges remain
on the A02 roadmap. The outbox stores pending results locally; this build does not
send them. This is not the final A02 submission.

## Primary workflow: WSL + VS Code

Use the [WSL development guide](../docs/a02/wsl-development.md). The existing Linux
toolchain is configured for this workspace; no SDK reinstallation is needed.
VS Code tasks analyze/test/build in WSL and can start the existing Windows emulator,
install the APK and launch the game without opening Android Studio.

## Windows setup (alternative)

1. Install [Git for Windows](https://git-scm.com/downloads/win) and
   [Android Studio](https://developer.android.com/studio) from their official sites.
2. From the repository root, open PowerShell and run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tools\setup-windows.ps1 -InstallFlutter
   ```

   This installs Flutter **3.50.0 / Dart 3.14.0** in your local application-data
   folder, verifies the SDK checksum, and adds its `bin` directory to your user PATH.
   Without `-InstallFlutter`, the script only checks the environment. Close and
   reopen PowerShell after installation. If scripts are disallowed by your system,
   follow the [official manual installation](https://docs.flutter.dev/install/manual)
   instead, choosing Flutter 3.50.0 from the archive.
   Downloads use `curl.exe` with resumable transfers and speed/ETA output. If a
   transfer is interrupted, rerun the same command: the partial ZIP at
   `%TEMP%\forest-flutter-3.50.0.zip` is retained. A checksum-verified complete ZIP
   is reused without downloading it again. Extraction starts only after checksum
   validation.
3. Complete Android Studio's Setup Wizard. In SDK Manager install Android API 36,
   SDK Build-Tools, Platform-Tools, Command-line Tools, and Android Emulator. Under
   **SDK Tools → Show Package Details → NDK (Side by side)**, install exactly
   **28.2.13676358**. This is Flutter 3.50.0's selected NDK; installing it explicitly
   avoids depending on automatic NDK provisioning during the first build. Use
   Android Studio's bundled full JDK or a full JDK 21 installation. A Java runtime
   alone is insufficient: Gradle also needs `javac`. CI uses Temurin JDK 21.
4. Run `flutter doctor -v` in PowerShell. If licenses are reported unaccepted, run
   `flutter doctor --android-licenses`. New Android command-line tools may instead
   report that `--licenses` is no longer needed; recheck doctor and accept any
   installation license dialogs shown by SDK Manager rather than looping that command.
5. Create and start an Android virtual device using Device Manager. Enable CPU
   virtualization if the emulator requests it. Alternatively connect an Android
   10+ phone with USB debugging enabled.

Keep the Windows development checkout on a Windows filesystem, for example
`C:\Projects\forest-sokoban`. Use Windows Flutter with Windows SDK/emulator. The
current WSL checkout can be used independently with a Linux SDK; mixing Windows
and Linux SDK/cache paths is not part of this setup.

### Automatic NDK installation fails

If the build reports `Android sdkmanager did not install NDK 28.2.13676358`, open
**Tools → SDK Manager → SDK Tools → Show Package Details**, expand
**NDK (Side by side)**, select **28.2.13676358**, and apply the installation.
Check that the SDK Location shown there matches `sdk.dir` in
`android/local.properties`. A completed installation includes
`ndk/28.2.13676358/source.properties` under that SDK location. Retry the build
after SDK Manager finishes. Do not change the selected NDK version or clear all
SDK/Gradle caches to resolve an installation failure. Official instructions:
[Install a specific NDK version](https://developer.android.com/studio/projects/install-ndk#specific-version).

### Windows Application Control blocks Dart

If Windows reports that `dart.exe` was blocked by Device Guard or Application
Control, the SDK download/extraction has already completed. Keep the installed SDK;
re-downloading it or selecting Android Studio does not resolve an execution-policy
block. Ask the device administrator to review the official SDK and approve it using
the applicable application-control policy. The setup script stops on SDK startup
errors and does not modify Windows security policy. See Microsoft's
[App Control troubleshooting guide](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/app-control-for-business/operations/appcontrol-debugging-and-troubleshooting).

## Run

From the repository root:

```powershell
cd app
flutter pub get --enforce-lockfile
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with an ID printed by `flutter devices`. No Supabase project,
account, secrets, or network connection is required at runtime for this foundation.
Initial SDK/package/Gradle downloads need network access.

Use the on-screen D-pad. On a keyboard, arrow keys/WASD move and U undoes.
Movement and successful Undo each cost one Step; blocked taps cost zero. A saved
attempt loads paused. Starting another level replaces the single unfinished save
only after confirmation. Personal progress is retained.

## Checks and builds

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --target-platform android-arm64 --no-pub
```

The arm64 APK is at `build/app/outputs/flutter-apk/app-debug.apk`. For an x86_64
emulator use `flutter run`, which chooses the device architecture automatically.
For a universal debug APK omit `--target-platform`. Install on an arm64 phone:

```powershell
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Release packaging/signing and physical-device acceptance are later A02 tasks.
The generated release configuration currently uses development signing; it must
be replaced for the final signed handoff. Do not commit signing keys.

In this WSL workspace, a local SDK is available in the ignored `.toolchains`
directory. From `app`, use `bash ../tools/flutterw analyze --no-pub` or
`bash ../tools/flutterw test --no-pub`. The local SDK is not included in Git.

## Architecture

`lib/domain` contains immutable boards, attempts and pure puzzle/progression rules.
`lib/data` implements SQLite transactions behind `CampaignRepository`.
`lib/viewmodels` commits serialized intents before publishing board state.
`lib/ui` renders the current supplied Figma designs as native Flutter widgets and handles navigation, semantic actions and swipe controls.

The twelve maps match Appendix A of the v1.1 report. All active screens now use
[the supplied Figma designs](https://www.figma.com/design/EbPr2cisVRC7wgbkLjKSp9?node-id=7-12421),
including fresh/saved Home, full More, map/chapters, three gameplay themes,
Pause/Restart/Level clear and guide. SVGs and all three fonts are bundled locally.
See [UI migration and availability](../docs/a02/figma-ui-migration.md) and
[asset provenance](../docs/a02/figma-assets-manifest.json). Reference screenshots
are never used as runtime backgrounds.

Start with **Play → The Awakening → First Steps**, then swipe on the board.
Use **More** for the other screens. A saved campaign exposes **Continue**.
Online account, rankings and challenge screens display unavailable messages;
story and audio playback remain pending. These interfaces do not imply a working backend.

Tests cover reference solutions, restore validation, timing, transaction rollback,
completion idempotency, score ordering, lifecycle, dialogs, and two landscape sizes
at 1.3x text. Host tests are not Android emulator/device acceptance or benchmarks.

A device smoke test is supplied but has not been executed here. On a clean test
installation, run `flutter test integration_test -d <android-device-id>` (optionally
in airplane mode). Clear test application data first if an existing save would
trigger a replacement confirmation. Never clear an actual player's data for a test.
