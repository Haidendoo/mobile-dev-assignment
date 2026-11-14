# Forest Sokoban — A02 Project Progress

**Baseline:** updated A01 report in `rp/A1_Mobile_dev.zip`, v1.1-r1.
**Platform:** Android 10+, landscape, Flutter/Dart.
**Language:** English. **Team:** two members; names not yet supplied.
**Schedule:** four relative weeks; actual mid-term/final dates not supplied.
**Last updated:** 14 November 2026 (Asia/Bangkok).

## Current status

A02 implementation has started. The first campaign foundation is implemented.
This is not the final A02 submission. Read [the application README](app/README.md)
for Windows setup/run commands and [the frozen plan](docs/a02/implementation-plan.md)
for the full scope and weekly ownership.

| Area | Status |
|---|---|
| Flutter toolchain | Flutter 3.50.0 / Dart 3.14.0 installed locally in ignored `.toolchains`; Windows setup script supplied |
| Android project | Generated, Android 10+ minimum, landscape, Gradle wrapper and dependency lockfile included |
| Canonical content | All 12 updated boards/versions and reference solutions bundled |
| Pure Dart rules | Movement, single-crate push, collision, Undo cost, history validation, completion freeze |
| Architecture | Views → ChangeNotifier ViewModel → pure domain / repository → SQLite |
| Campaign UI | Home, chapter/level selection, Guide, gameplay, paused/completed overlays and confirmation dialogs |
| Local persistence | Save/resume, personal best pairs, atomic completion and pending score outbox |
| Automated checks | See actual results in `docs/a02/verification.md`; not device acceptance |
| Android build | Debug arm64 APK built; API 29 minimum, API 36 target; APK signature verified |
| Windows setup/runtime | Script and instructions prepared; not run on the user's Windows installation |
| Research/Figma | Updated report/mockups used as references; viewer/runtime and user-study evidence not revalidated |
| Story and ending | Not implemented |
| Music/SFX/settings | Not implemented |
| Supabase/Auth/OTP | Not deployed or integrated |
| Rankings/challenges | Updated contract copied; runtime integration not implemented |
| Release/device acceptance | Not executed |

## Week 1 — Foundation

- [x] Record the updated baseline and preserve historical A01 artifacts.
- [x] Create the Flutter Android project with dependency lockfile.
- [x] Implement all twelve canonical boards and pure puzzle rules.
- [x] Implement serialized intents, active timer, pause and save restoration.
- [x] Implement SQLite completion/progress/outbox transaction.
- [x] Implement Home, level selection, Guide and gameplay foundation.
- [x] Add core/database/widget tests and CI workflow source.
- [x] Supply a Windows Flutter installation/check script and setup guide.
- [x] Build a signed debug arm64 APK and repeat the build from a clean source copy in WSL.
- [ ] Verify CI on the remote repository (workflow has not been run remotely).
- [ ] Verify Android install/runtime on an emulator and physical device.
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
- [ ] Borrow Android hardware (4 GB RAM or more) for release performance samples.
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
