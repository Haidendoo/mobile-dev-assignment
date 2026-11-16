# WSL + VS Code development

This is the primary development workflow from 16 November 2026. Edit the WSL
checkout at `/home/haiden/bku/mobile`; the Windows OneDrive checkout is a separate
copy. Do not alternate edits between the two without committing/synchronizing.
No new Flutter, Java or Android Studio installation is required on this machine.

## Demo hardware

The user's confirmed demo device is **Samsung Galaxy S21+** (16 November 2026).
Use that phone for the final install/run demonstration and physical-device NFR
measurements. Record its actual Android version, OS build and device details when
connected. Physical-device installation, USB debugging connectivity and performance
measurements remain pending; emulator checks do not count as results on this phone.

## Open the workspace

In Ubuntu/WSL:

```bash
cd /home/haiden/bku/mobile
source tools/env-wsl.sh
code .
```

The VS Code lower-left remote indicator must say **WSL: Ubuntu**. Open the entire
repository root so the workspace tasks find `app/` and `tools/`. Dart and Flutter
extensions are installed in the WSL extension host. If the folder was already open,
run **Developer: Reload Window** once and open a **new** integrated terminal.

`tools/setup-wsl.sh` has configured the Linux Flutter/Dart SDK, JDK, Android SDK,
cache locations, formatter and terminal PATH. It can be rerun without downloading
tools:

```bash
bash tools/setup-wsl.sh
```

The generated `.vscode/settings.json` has machine-specific absolute paths and is
ignored by Git. Other `.vscode` task/extension/launch definitions are portable.
Existing strict-JSON settings are merged; commented JSON files are preserved and
require manual merging. This script does not modify Windows security policies,
firewall rules, shell startup files or WSL networking.

## Code, analyze and test

From a new VS Code terminal with the configured environment:

```bash
cd app
which flutter
flutter --version
flutter analyze --no-pub
flutter test --no-pub
```

`which flutter` must resolve inside `/home/haiden/bku/mobile/.toolchains/flutter`,
not `/mnt/c/.../flutter`. In an external WSL terminal source `tools/env-wsl.sh`
first. The existing `tools/flutterw` wrapper also supplies the local toolchain.

VS Code **Terminal → Run Task** provides:

| Task | Action |
|---|---|
| Flutter: Analyze (WSL) | Analyze application source |
| Flutter: Test (WSL) | Execute the host test suite |
| Android: Build emulator APK (WSL) | Linux build of debug x86_64 APK |
| Android: Start Windows emulator | Start the existing AVD without opening Android Studio |
| Android: Build and install on Windows emulator | Build in WSL, install through Windows ADB, launch the game |

The F5 launch configuration is for **Flutter tests (WSL)**. Android F5/hot reload
requires an Android device reachable by Linux ADB; that bridge has not been
configured here. The APK installation tasks below work without that bridge.

## View the game without Android Studio

From the repository root:

```bash
bash tools/windows-emulator.sh start
```

Wait for the Android Home screen. Then use **Android: Build and install on Windows
emulator** in VS Code. The equivalent terminal commands are:

```bash
cd /home/haiden/bku/mobile
source tools/env-wsl.sh
cd app
flutter build apk --debug --target-platform android-x64 --no-pub
cd ..
bash tools/windows-emulator.sh install
```

The helper discovers the existing Windows SDK, uses WSL path conversion to read
the built APK, installs with `adb install -r -t`, and launches the application.
It does not clear existing app data. It requires Windows/WSL executable interop.
Device IDs/AVD names can be supplied when more than one exists:

```bash
bash tools/windows-emulator.sh list
bash tools/windows-emulator.sh start Medium_Phone_API_37.0
bash tools/windows-emulator.sh install emulator-5554
```

If an existing Windows-installed development build reports
`INSTALL_FAILED_UPDATE_INCOMPATIBLE`, the debug signing keys differ. On this
machine, setup has reused the existing Windows debug keystore, preserving the
original WSL key as `.toolchains/android-user/debug.keystore.before-windows-sync`.
To perform that same explicit setup on another matching checkout:

```bash
bash tools/setup-wsl.sh --windows-debug-key /mnt/c/Users/tranh/.android/debug.keystore
```

Then rebuild the APK. This is development signing only; keys and their backups
remain ignored by Git. No application uninstall or data clearing is needed when
updating with the same signing identity. Other devices previously using the old
WSL debug key need their original signing identity retained.

Only the emulator/Windows ADB run on Windows; editor, Dart analysis, host tests,
Gradle and APK compilation run in WSL using Linux tools. This workflow deliberately
uses APK redeployment, not hot reload. No ADB service is exposed over the LAN and
no firewall/network settings are changed.

## Troubleshooting boundaries

- A successful Android build does not require Chrome or Linux desktop build tools.
- `flutter devices` in WSL can be empty while Windows ADB sees the emulator. Use
  the supplied helper for this workflow; do not select a Linux/Windows desktop target.
- If the helper reports Android still booting, wait for Home and retry installation.
- ADB/network checks executed inside the Codex sandbox may need execution approval;
  those sandbox restrictions do not indicate a broken SDK in your regular terminal.
- If dependencies change, run `flutter pub get` and review the lockfile changes.
- The existing Windows setup guide remains available for reference; it is not the
  primary development workflow now.
