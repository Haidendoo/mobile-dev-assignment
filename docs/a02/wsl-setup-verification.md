# WSL setup verification — 16 November 2026

Primary workspace: `/home/haiden/bku/mobile`, VS Code remote host **WSL: Ubuntu**.

| Check | Observed result |
|---|---|
| Linux Flutter/Dart resolution | Both resolve inside the repository's `.toolchains/flutter`, ahead of Windows SDK paths |
| SDK versions | Flutter 3.50.0, Dart 3.14.0, Temurin JDK 21.0.13 |
| Android toolchain | `flutter doctor -v`: check passed, Android API 36, Build-Tools 36.0.0, all Android licenses accepted |
| Remote editor extensions | `code --list-extensions`: Dart and Flutter installed on WSL: Ubuntu |
| Analysis | No issues found |
| Host tests | 38 passed |
| Android build | Debug x86_64 APK built successfully with the Linux toolchain |
| Start emulator from WSL | Existing `Medium_Phone_API_37.0` started without opening Android Studio |
| Install update | Windows ADB returned `Success` for the WSL-built APK |
| Launch game | ADB started `edu.hcmut.forest_sokoban/.MainActivity` |
| Foreground check | Android `dumpsys activity activities` showed that activity as `topResumedActivity` |
| Workspace configuration | JSON parsed; Bash syntax checks and Git whitespace check passed |

Debug x86_64 APK SHA-256 from the earlier environment setup check (later UI builds replace that artifact):
`9db614eb2fe4f5f22a9549bca3f62ea23c627f41607da3f42450c1799b4d2262`.

An initial update attempt failed because Windows and WSL used different debug
signing identities. Setup explicitly reused the existing Windows debug keystore,
backed up the WSL key, rebuilt and installed successfully. No uninstall or app-data
reset was performed. Keys/backups are inside ignored paths and never committed.

The Android-only Linux Flutter configuration disables unused web/Linux desktop
targets. Linux ADB currently has no connected Android devices; doctor retains that
single device warning. The verified workflow uses Windows ADB through WSL interop
for installation, without an ADB network bridge. Android F5/hot reload is not
configured. The supplied F5 configuration runs Flutter tests.

This verifies the development toolchain and build/install/launch path, not the full
A02 acceptance matrix, performance thresholds, live backend, or physical hardware.
