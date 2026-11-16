# Figma UI migration — 16 November 2026

## Design source and implementation

The active interface now uses [the supplied Figma file](https://www.figma.com/design/EbPr2cisVRC7wgbkLjKSp9?node-id=7-12421). The former foundation backdrop, panels, vector board and directional pad have been removed from the application. Historical A01 files under `prototype/` and `deliverables/` remain reference artifacts.

| Runtime view | Figma reference |
|---|---|
| Fresh Home / saved Home | `7:11079` / `7:12421` |
| More | `7:12213` |
| World Map / chapters | `13:103`, `23:159`, `23:193`, `23:222` |
| Locked chapters | `13:125`, `13:131` |
| Forest / ruins / heartwood gameplay | `7:11289`, `23:110`, `23:138` |
| Pause / Restart / Level clear | `7:12632`, `7:13711`, `7:11999` |
| How to Play / rules | `7:14068`, `24:14890` |
| Settings, both audio channels off | `13:1219` |
| Profile / email entry / sign-in entry | `13:1305`, `13:1325`, `13:1361` |
| Challenge Hub / create / join / rooms | `13:1397`, `13:1402`, `13:1408`, `24:14562` |
| Leaderboard unavailable / level picker | `24:14544`, `24:14302` |
| Story Archive / overview | `13:137`, `16:89` |

`tools/compile-figma-scenes.py` translates the reviewed MCP reference contexts into `figma_scenes.g.dart`. The Flutter renderer creates native text, containers, SVG layers, semantic actions and touch regions. It runs no JavaScript, WebView or remote asset fetches. Rebuild the generated scene data with `python3 tools/compile-figma-scenes.py`; the already-downloaded SVG files remain bundled under `app/assets/figma/`. The contexts and asset manifest record provenance, not runtime network dependencies. Variable font axes are set explicitly so the installed Android app uses the same weights as the Figma reference, independently of host preview font loading.

Cormorant Garamond, DM Sans and IBM Plex Mono are bundled with their OFL licenses. The Figma screenshots are comparison targets and are never used as runtime backgrounds. App-rendered previews are in `docs/a02/figma-ui-previews/`.

## Runtime bindings and deliberate adaptations

- Fresh installs show Play; a valid unfinished save shows Continue and the actual level name.
- Chapters use actual unlock state and stored personal bests. Game titles, counters, time, objective counts and result statistics come from the ViewModel.
- Swiping the live board moves one cell. Keyboard arrows/WASD and U remain available. TalkBack receives explicit button tap actions and four custom directional actions on the board. Touch regions have a minimum size of 48 logical pixels after scene scaling.
- Pause, background handling, Undo costs, restart confirmation and SQLite persistence retain their existing rules. A damaged save can be explicitly discarded through the new confirmation surface without removing completed progress.
- The playable maps and versions remain the canonical twelve-map A01 v1.1 baseline. Later Figma demo boards use different v3/v4 sample geometry; those sample maps are not silently substituted for the accepted data. Live terrain is rendered from the canonical map with the corresponding Figma chapter palette and sprites. Version labels and objective counts use the actual data.
- Native confirmation and save-error surfaces reuse the Figma dialog styling, with messages appropriate to the real state. A goal-occupied piece receives an additional check badge for non-color identification.

## Feature availability

This completes the interface migration, not Assignment 02. Campaign gameplay, local saves, progress and pending score storage work. Online Auth/OTP, real rankings and verified challenge rooms are not configured. Their design screens show unavailable states/messages rather than fabricated online results. Story playback and audio playback/toggle persistence remain pending; Settings uses the actual both-Off design.

## Verification

- Failing navigation tests reproduced the old More dialog, stale unlock text, missing new chapter theme, inaccessible scene buttons and More Back self-loop before the corresponding fixes.
- Static asset audit: 141 non-empty scene SVGs and 167 scene image slots checked; no SVG/wrapper aspect-ratio mismatches. See `figma-asset-audit.json`.
- Latest host suite: **50 tests passed**, covering pure rules, all canonical reference solutions, SQLite transactions, ViewModel lifecycle/save behavior, new navigation, restored progress and semantic actions.
- Layout/play/restart/resume coverage includes 640×360, 800×360, 800×450 and 960×432 with 1.3× text.
- Preview walkthrough captures fresh Home, More, map, chapter, all three gameplay themes, Pause, Restart, Level clear, guide, rules, Profile, Settings and the unavailable leaderboard.
- Physical Samsung Galaxy S21+ acceptance, TalkBack on the device, release performance and full A02 backend/manual acceptance remain pending. Host tests and rendered previews do not establish those results.

## AI assistance and review status

Codex assisted with reading the user-provided Figma design through MCP, compiling layout data, adapting native Flutter views and controls, regression tests, review and documentation. Automated tests, generated previews and the asset audit provide the recorded evidence. Team member understanding, contribution attribution, visual approval and physical-device acceptance must be recorded by the team; they are not claimed here.

## Installed Android build

The final debug APK includes ARM64 for Samsung Galaxy S21+ and x86_64 for the Windows emulator. It was built in WSL, installed with an in-place update preserving app data, and launched on Android API 37. The new More screen was opened through the actual Android accessibility tree and visually inspected. The inspected native More screenshot is `figma-ui-previews/android-more.png`; the other screen previews are captured by the Flutter walkthrough. An emulator process exited during the first installation attempt; restarting the same AVD without wiping data allowed the update to complete.

Build checksum, size and ABI evidence: `figma-ui-build.json`. The APK is `app/build/app/outputs/flutter-apk/app-debug.apk`. This remains a debug build; the release signing/build and physical S21+ checks are separate A02 tasks.

The subsequent [push motion polish](push-motion.md) updates the APK at the same output path. See `push-build.json` for its current checksum and verification; `figma-ui-build.json` records the earlier UI migration build.
