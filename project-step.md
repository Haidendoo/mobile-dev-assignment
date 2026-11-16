# Forest Sokoban — A02 Project Progress

**Baseline:** updated A01 report in `rp/A1_Mobile_dev.zip`, v1.1-r1.
**Platform:** Android 10+, landscape, Flutter/Dart.
**Language:** English. **Team:** two members; names not yet supplied.
**Schedule:** four relative weeks; actual mid-term/final dates not supplied.
**Last updated:** 16 November 2026 (Asia/Bangkok).
**Development environment:** WSL Ubuntu + VS Code, using the existing Linux toolchain.
**Demo device:** Samsung Galaxy S21+ (confirmed by the user on 16 November 2026).
See [the WSL guide](docs/a02/wsl-development.md).

## Current status

A02 implementation has started. The offline campaign and migration of active screens to the supplied Figma UI are implemented.
This is not the final A02 submission. Read [the application README](app/README.md)
for run commands and alternative Windows setup and [the frozen plan](docs/a02/implementation-plan.md)
for the full scope and weekly ownership.

| Area | Status |
|---|---|
| Flutter toolchain | WSL Linux Flutter 3.50.0 / Dart 3.14.0, JDK 21 and Android SDK configured; VS Code uses the Linux SDK |
| Android project | Generated, Android 10+ minimum, landscape, Gradle wrapper and dependency lockfile included |
| Canonical content | All 12 updated boards/versions and reference solutions bundled |
| Pure Dart rules | Movement, single-crate push, collision, Undo cost, history validation, completion freeze |
| Architecture | Views → ChangeNotifier ViewModel → pure domain / repository → SQLite |
| Campaign UI | Active screens use the supplied Figma designs; Play/Continue, full More, map/chapters, swipe gameplay with three themes, animated pushes/altar feedback, dialogs and result UI |
| Local persistence | Save/resume, personal best pairs, atomic completion and pending score outbox |
| Automated checks | Latest push animation polish: 53 host tests passed; see `docs/a02/push-motion.md`; full device acceptance remains pending |
| Android build | Current Figma debug APK includes ARM64 (Samsung S21+) and x86_64; built in WSL and installed/launched on API 37 Windows emulator; physical acceptance pending |
| Windows setup/runtime | User reported successful x86_64 APK build and game launch on Android API 37 emulator on 15 November; full manual acceptance remains pending |
| Research/Figma | Updated report/mockups used as references; viewer/runtime and user-study evidence not revalidated |
| Story and ending | Not implemented |
| Music/SFX/settings | Figma both-Off Settings screen present; playback and persisted controls not implemented |
| Supabase/Auth/OTP | Not deployed or integrated |
| Rankings/challenges | New Figma screens/unavailable messages present; runtime backend integration not implemented |
| Release/device acceptance | Not executed |

## Week 1 — Foundation

- [x] Record the updated baseline and preserve historical A01 artifacts.
- [x] Create the Flutter Android project with dependency lockfile.
- [x] Implement all twelve canonical boards and pure puzzle rules.
- [x] Implement serialized intents, active timer, pause and save restoration.
- [x] Implement SQLite completion/progress/outbox transaction.
- [x] Implement Home, level selection, Guide and gameplay foundation.
- [x] Replace active foundation UI with the supplied Figma designs and swipe controls; preserve canonical maps and saved progress.
- [x] Add core/database/widget tests and CI workflow source.
- [x] Supply a Windows Flutter installation/check script and setup guide.
- [x] Configure WSL + VS Code SDK paths, terminal environment, analysis/test/build and emulator tasks.
- [x] Build a signed debug arm64 APK and repeat the build from a clean source copy in WSL.
- [ ] Verify CI on the remote repository (workflow has not been run remotely).
- [x] Verify WSL build → Windows emulator installation and activity launch without Android Studio.
- [ ] Complete emulator manual acceptance and physical-device validation.
- [ ] Create Supabase local/hosted environments and prove same-ID email linking.
- [ ] Team review of foundation artwork, architecture and baseline changes.

## Week 2 — Campaign completion and online scores

- [ ] Bundle English chapter/story scripts; implement Next/Skip/Replay and ending recovery.
- [ ] Bundle licensed/original audio; implement contextual BGM and independent SFX.
- [ ] Persist toggles/volumes and test lifecycle/audio behavior.
- [ ] Implement secure session storage, anonymous Auth, same-ID link and OTP sign-in.
- [ ] Implement score RPCs/RLS and owner-bound publication of pending results.
- [ ] Implement leaderboard loading/empty/error/offline/cache states.
- [ ] Deliver preliminary APK and collect mid-term feedback.

## Week 3 — Verified asynchronous challenges

- [ ] Implement create/join/list/status/cancel room RPCs.
- [ ] Implement shared Dart/TypeScript rule fixtures and server trace replay.
- [ ] Implement server-only atomic finalizer, deadlines and receipts.
- [ ] Implement account-scoped challenge attempts, outbox/cache and recovery.
- [ ] Implement Challenge Hub/room/result screens and all failure states.
- [ ] Test two-client flow, authorization, concurrency, retries and clock skew.
- [ ] Finish four Should refinements or document reviewed deferrals and fallbacks.

## Week 4 — Acceptance and handoff

- [ ] Execute all Must/Should acceptance cases and 21 NFR checks.
- [ ] Use the Samsung Galaxy S21+ demo device for release performance samples; record its actual Android version, build and device details before measuring.
- [ ] Complete two-size layout, enlarged text, TalkBack and permission review.
- [ ] Produce final signed release APK/checksum and perform clean-checkout build/run.
- [ ] Complete manual results, traceability, asset sources, contribution and AI declarations.
- [ ] Rehearse offline campaign, story/audio, score retry, OTP and verified challenge demo.

## Change and evidence policy

Use short feature branches and incremental commits/PRs reviewed by the other member.
No commits or PRs have been fabricated by this implementation session. Record actual
team identities, reviews and contributions as they occur. Design changes are tracked
in `docs/a02/change-log.csv`; the supplied entries await team review.

`docs/a02/manual-tests.csv` lists device/manual scenarios with honest pending status.
Host tests do not prove Android runtime, physical-device performance, production
accessibility, Figma usability, or deployed backend behavior. The README build/run
gate must pass before submission; failure caps A02 at 40/100.

The original `docs/`, `data/levels.json`, `prototype/`, and `deliverables/` A01 package
remain historical. Do not rerun its generator to overwrite A02 contract/content.
